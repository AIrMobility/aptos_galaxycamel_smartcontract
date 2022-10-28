module galaxycamel::marketplace{
    use std::signer;
    use std::string::String;
    use aptos_framework::guid;
    use aptos_framework::coin;
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_std::event::{Self, EventHandle};    
    use aptos_std::table::{Self, Table};
    use aptos_token::token;
    // use aptos_token::token_coin_swap::{ list_token_for_swap, exchange_coin_for_token };

    const ESELLER_CAN_NOT_BE_BUYER: u64 = 1;
    const ENO_AUTHROIZED_SELLER: u64 = 2;
    const ENO_SUFFICIENT_FUND: u64 = 3;


    const FEE_DENOMINATOR: u64 = 10000;

    struct MarketId has store, drop, copy {
        market_name: String,
        market_address: address,
    }

    struct Market has key {
        market_id: MarketId,
        fee_numerator: u64,
        fee_payee: address,
        signer_cap: account::SignerCapability
    }

    struct MarketEvents has key {
        create_market_event: EventHandle<CreateMarketEvent>,
        list_token_events: EventHandle<ListTokenEvent>,        
        buy_token_events: EventHandle<BuyTokenEvent>,
        delist_token_events: EventHandle<DeListTokenEvent>,
    }

    struct OfferStore has key {
        offers: Table<token::TokenId, Offer>
    }

    struct Offer has drop, store {
        market_id : MarketId,
        seller: address,
        price: u64,
    }

    struct CreateMarketEvent has drop, store {
        market_id: MarketId,
        fee_numerator: u64,
        fee_payee: address,
    }

    struct ListTokenEvent has drop, store {
        market_id: MarketId,
        token_id: token::TokenId,
        seller: address,
        price: u64,
        timestamp: u64,
        offer_id: u64
    }

    struct DeListTokenEvent has drop, store {
        market_id: MarketId,
        token_id: token::TokenId,
        timestamp: u64     
    }

    struct BuyTokenEvent has drop, store {
        market_id: MarketId,
        token_id: token::TokenId,
        seller: address,
        buyer: address,
        price: u64,
        timestamp: u64,
        offer_id: u64
    }

    fun get_resource_account_cap(market_address : address) : signer acquires Market{
        let market = borrow_global<Market>(market_address);
        account::create_signer_with_capability(&market.signer_cap)
    }

    fun get_royalty_fee_rate(token_id: token::TokenId) : u64{
        let royalty = token::get_royalty(token_id);
        let royalty_denominator = token::get_royalty_denominator(&royalty);
        let royalty_fee_rate = if (royalty_denominator == 0) {
            0
        } else {
            token::get_royalty_numerator(&royalty) / token::get_royalty_denominator(&royalty)
        };
        royalty_fee_rate
    }

    public entry fun create_market<CoinType>(sender: &signer, market_name: String, fee_numerator: u64, fee_payee: address, initial_fund: u64) acquires MarketEvents, Market {        
        let sender_addr = signer::address_of(sender);
        let market_id = MarketId { market_name, market_address: sender_addr };
        if(!exists<MarketEvents>(sender_addr)){
            move_to(sender, MarketEvents{
                create_market_event: account::new_event_handle<CreateMarketEvent>(sender),
                list_token_events: account::new_event_handle<ListTokenEvent>(sender),
                buy_token_events: account::new_event_handle<BuyTokenEvent>(sender),
                delist_token_events: account::new_event_handle<DeListTokenEvent>(sender)
            });
        };
        if(!exists<OfferStore>(sender_addr)){
            move_to(sender, OfferStore{
                offers: table::new()
            });
        };
        if(!exists<Market>(sender_addr)){
            let (resource_signer, signer_cap) = account::create_resource_account(sender, x"01");
            token::initialize_token_store(&resource_signer);
            move_to(sender, Market{
                market_id, fee_numerator, fee_payee, signer_cap
            });
            let market_events = borrow_global_mut<MarketEvents>(sender_addr);
            event::emit_event(&mut market_events.create_market_event, CreateMarketEvent{ market_id, fee_numerator, fee_payee });
        };
        let resource_signer = get_resource_account_cap(sender_addr);
        if(!coin::is_account_registered<CoinType>(signer::address_of(&resource_signer))){
            coin::register<CoinType>(&resource_signer);
        };
        if(initial_fund > 0){
            coin::transfer<CoinType>(sender, signer::address_of(&resource_signer), initial_fund);
        }
    }

    public entry fun list_token<CoinType>(seller: &signer, market_address:address, market_name: String, creator: address, collection: String, name: String, property_version: u64, price: u64) acquires MarketEvents, Market, OfferStore {
        let market_id = MarketId { market_name, market_address };
        let resource_signer = get_resource_account_cap(market_address);
        let seller_addr = signer::address_of(seller);
        let token_id = token::create_token_id_raw(creator, collection, name, property_version);
        let token = token::withdraw_token(seller, token_id, 1);

        token::deposit_token(&resource_signer, token);
        // list_token_for_swap<CoinType>(&resource_signer, creator, collection, name, property_version, 1, price, 0);

        let offer_store = borrow_global_mut<OfferStore>(market_address);
        table::add(&mut offer_store.offers, token_id, Offer {
            market_id, seller: seller_addr, price
        });

        let guid = account::create_guid(&resource_signer);
        let market_events = borrow_global_mut<MarketEvents>(market_address);
        event::emit_event(&mut market_events.list_token_events, ListTokenEvent{
            market_id, 
            token_id, 
            seller: seller_addr, 
            price, 
            timestamp: timestamp::now_microseconds(),
            offer_id: guid::creation_num(&guid)
        });
    }

    public fun delist_token<CoinType>(seller: &signer, market_address:address, market_name: String, creator: address, collection: String, name: String, property_version: u64) acquires MarketEvents, Market, OfferStore {
        let market_id = MarketId { market_name, market_address };
        let token_id = token::create_token_id_raw(creator, collection, name, property_version);
        let offer_store = borrow_global_mut<OfferStore>(market_address);
        let seller_store = table::borrow(&offer_store.offers, token_id).seller;                        
        assert!(signer::address_of(seller) != seller_store, ENO_AUTHROIZED_SELLER);
        
        let resource_signer = get_resource_account_cap(market_address);
        // cancel_token_listing<CoinType>(&resource_signer, token_id, 1);
        // let resource_signer = account::create_signer_with_capability(&collection_token_minter.signer_cap);
        // let token_id = token::mint_token(&resource_signer, collection_token_minter.token_data_id, 1);
        // token::direct_transfer(&resource_signer, receiver, token_id, 1);     

        let token = token::withdraw_token(&resource_signer, token_id, 1);
        token::deposit_token(seller, token);
        table::remove(&mut offer_store.offers, token_id);    

        let market_events = borrow_global_mut<MarketEvents>(market_address);
        event::emit_event(&mut market_events.delist_token_events, DeListTokenEvent{
            market_id,
            token_id,
            timestamp: timestamp::now_microseconds(),            
        });    
    } 

    public entry fun buy_token<CoinType>(buyer: &signer, market_address: address, market_name: String, creator: address, collection: String, name: String, property_version: u64, price: u64, offer_id: u64) acquires MarketEvents, Market, OfferStore{
        let market_id = MarketId { market_name, market_address };
        let token_id = token::create_token_id_raw(creator, collection, name, property_version);
        let offer_store = borrow_global_mut<OfferStore>(market_address);
        let seller = table::borrow(&offer_store.offers, token_id).seller;        
        let buyer_addr = signer::address_of(buyer);
        
        assert!(seller != buyer_addr, ESELLER_CAN_NOT_BE_BUYER);
        assert!(coin::balance<CoinType>(buyer_addr) >= price, ENO_SUFFICIENT_FUND);

        let resource_signer = get_resource_account_cap(market_address);
        // exchange_coin_for_token<CoinType>(buyer, price, signer::address_of(&resource_signer), creator, collection, name, property_version, 1);
        
        
        // send token from valut
        let token = token::withdraw_token(&resource_signer, token_id, 1);
        token::deposit_token(buyer, token);
        
        // royalty deduction
        let royalty = token::get_royalty(token_id);
        let royalty_fee = price * get_royalty_fee_rate(token_id);        
        let royalty_payee = token::get_royalty_payee(&royalty);
        coin::transfer<CoinType>(&resource_signer, royalty_payee, royalty_fee);

        // marketfee deduction
        let market = borrow_global<Market>(market_address);
        let market_fee = price * market.fee_numerator / FEE_DENOMINATOR;
        let amount = price - market_fee - royalty_fee;
        coin::transfer<CoinType>(&resource_signer, seller, amount);

        table::remove(&mut offer_store.offers, token_id);
        let market_events = borrow_global_mut<MarketEvents>(market_address);
        event::emit_event(&mut market_events.buy_token_events, BuyTokenEvent{
            market_id,
            token_id, 
            seller, 
            buyer: buyer_addr, 
            price,
            timestamp: timestamp::now_microseconds(),
            offer_id
        });
    }
}