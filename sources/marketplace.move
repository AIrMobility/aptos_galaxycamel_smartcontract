module galaxycamel::marketplace{
    use std::signer;
    use std::string::String;
    use aptos_framework::guid;
    // use aptos_framework::coin;
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_framework::coin::{Self, Coin};
    use aptos_std::event::{Self, EventHandle};    
    use aptos_std::table::{Self, Table};
    use aptos_token::token;    
    // coin pack: https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-framework/sources/coin.move
    const ESELLER_CAN_NOT_BE_BUYER: u64 = 1;
    const ENO_AUTHROIZED_SELLER: u64 = 2;
    const ENO_SUFFICIENT_FUND: u64 = 3;


    const FEE_DENOMINATOR: u64 = 100000;

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
        list_sell_token_events: EventHandle<ListSellTokenEvent>,        
        delist_sell_token_events: EventHandle<DeListSellTokenEvent>,
        list_buy_token_events: EventHandle<ListBuyTokenEvent>,        
        delist_buy_token_events: EventHandle<DeListBuyTokenEvent>,
        buy_token_events: EventHandle<BuyTokenEvent>,
        sell_token_events: EventHandle<SellTokenEvent>,
    }

    struct SellOfferStore has key {
        offers: Table<token::TokenId, SellOffer>
    }

    struct SellOffer has drop, store {
        market_id : MarketId,
        seller: address,
        price: u64,
    }

    struct BuyOfferStore has key {
        offers: Table<u64, BuyOffer>
    }

    struct BuyOffer has drop, store {
        market_id : MarketId,
        buyer: address,
        price: u64,
        collection_id: CollectionId
    }

    struct CreateMarketEvent has drop, store {
        market_id: MarketId,
        fee_numerator: u64,
        fee_payee: address,
    }

    struct ListSellTokenEvent has drop, store {
        market_id: MarketId,
        token_id: token::TokenId,
        seller: address,
        price: u64,
        timestamp: u64,
        offer_id: u64
    }

    struct DeListSellTokenEvent has drop, store {
        market_id: MarketId,        
        token_id: token::TokenId,
        seller: address,
        timestamp: u64     
    }

    struct ListBuyTokenEvent has drop, store {
        market_id: MarketId,
        collection_id: CollectionId,
        buyer: address,
        price: u64,
        timestamp: u64,
        offer_id: u64
    }

    struct DeListBuyTokenEvent has drop, store {
        market_id: MarketId,
        collection_id: CollectionId,
        buyer: address,
        offer_id: u64,
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

    struct SellTokenEvent has drop, store {
        market_id: MarketId,
        token_id: token::TokenId,
        seller: address,
        buyer: address,
        price: u64,
        timestamp: u64,
        offer_id: u64
    }

    struct CollectionId has store, copy, drop {
        creator: address,
        name: String,
    }
    
    fun get_resource_account_cap(market_address : address) : signer acquires Market{
        let market = borrow_global<Market>(market_address);
        account::create_signer_with_capability(&market.signer_cap)
    }

    public fun create_collection_data_id(
        creator: address,
        name: String        
    ): CollectionId {        
        CollectionId { creator, name }
    }

    public entry fun create_market<CoinType>(sender: &signer, market_name: String, fee_numerator: u64, fee_payee: address, initial_fund: u64) acquires MarketEvents, Market {        
        let sender_addr = signer::address_of(sender);
        let market_id = MarketId { market_name, market_address: sender_addr };
        if(!exists<MarketEvents>(sender_addr)){
            move_to(sender, MarketEvents{
                create_market_event: account::new_event_handle<CreateMarketEvent>(sender),
                list_sell_token_events: account::new_event_handle<ListSellTokenEvent>(sender),
                delist_sell_token_events: account::new_event_handle<DeListSellTokenEvent>(sender),
                list_buy_token_events: account::new_event_handle<ListBuyTokenEvent>(sender),
                delist_buy_token_events: account::new_event_handle<DeListBuyTokenEvent>(sender),
                buy_token_events: account::new_event_handle<BuyTokenEvent>(sender),
                sell_token_events: account::new_event_handle<SellTokenEvent>(sender),                
            });
        };
        if(!exists<SellOfferStore>(sender_addr)){
            move_to(sender, SellOfferStore{
                offers: table::new()
            });
        };
        if(!exists<BuyOfferStore>(sender_addr)){
            move_to(sender, BuyOfferStore{
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
    
    public entry fun deposit_gov_token(govener: &signer, market_name: String, creator: address, collection: String, name: String, property_version: u64, amount:u64) {
        let market_id = MarketId { market_name, market_address: sender_addr };
        let token_id = token::create_token_id_raw(creator, collection, name, property_version);
        let resource_signer = get_resource_account_cap(market_address);        
        let token = token::withdraw_token(seller, token_id, amount);
        token::deposit_token(&resource_signer, token);
    }

    public entry fun withdraw_gov_token(govener: &signer, market_name: String, creator: address, collection: String, name: String, property_version: u64) {
        let market_id = MarketId { market_name, market_address: sender_addr };
        let token_id = token::create_token_id_raw(creator, collection, name, property_version);
        let resource_signer = get_resource_account_cap(market_address);
        let token = token::withdraw_token(resource_signer, token_id, amount);
        token::deposit_token(signer::address_of(govener);, token);
    }

    public entry fun list_buy_token_offer<CoinType>(buyer: &signer, market_address:address, market_name: String, creator: address, collection_name: String, price: u64) acquires MarketEvents, Market, BuyOfferStore {
        let market_id = MarketId { market_name, market_address };
        let resource_signer = get_resource_account_cap(market_address);
        let buyer_addr = signer::address_of(buyer);
        let collection_id = create_collection_data_id(creator, collection_name);
        let guid = account::create_guid(&resource_signer);
        let offer_id = guid::creation_num(&guid);

        let coins = coin::withdraw<CoinType>(buyer, price);
        coin::deposit(signer::address_of(&resource_signer), coins);

        let offer_store = borrow_global_mut<BuyOfferStore>(market_address);
        
        table::add(&mut offer_store.offers, offer_id, BuyOffer {
            market_id, buyer: buyer_addr, price: price, collection_id: collection_id
        });
        
        let market_events = borrow_global_mut<MarketEvents>(market_address);
        event::emit_event(&mut market_events.list_buy_token_events, ListBuyTokenEvent{
            market_id, 
            collection_id, 
            buyer: buyer_addr, 
            price, 
            timestamp: timestamp::now_microseconds(),
            offer_id: offer_id
        });
    }

    public entry fun delist_buy_token_offer<CoinType>(buyer: &signer, market_address:address, market_name: String, creator: address, collection_name: String, offer_id: u64) acquires MarketEvents, Market, BuyOfferStore {
        let market_id = MarketId { market_name, market_address };
        let collection_id = create_collection_data_id(creator, collection_name);
        let offer_store = borrow_global_mut<BuyOfferStore>(market_address);
        let buyer_store = table::borrow(&offer_store.offers, offer_id).buyer;
        let buyer_addr = signer::address_of(buyer);
        let price = table::borrow(&offer_store.offers, offer_id).price;
        assert!(buyer_addr == buyer_store, ENO_AUTHROIZED_SELLER);
        
        let resource_signer = get_resource_account_cap(market_address);
        let coins = coin::withdraw<CoinType>(&resource_signer, price);
        coin::deposit(buyer_addr, coins);

        table::remove(&mut offer_store.offers, offer_id);    

        let market_events = borrow_global_mut<MarketEvents>(market_address);
        
        event::emit_event(&mut market_events.delist_buy_token_events, DeListBuyTokenEvent{
            market_id,
            collection_id, 
            offer_id,            
            buyer: buyer_addr,             
            timestamp: timestamp::now_microseconds()            
        });
    }

    public entry fun list_sell_token_offer<CoinType>(seller: &signer, market_address:address, market_name: String, creator: address, collection: String, name: String, property_version: u64, price: u64) acquires MarketEvents, Market, SellOfferStore {
        let market_id = MarketId { market_name, market_address };
        let resource_signer = get_resource_account_cap(market_address);
        let seller_addr = signer::address_of(seller);
        let token_id = token::create_token_id_raw(creator, collection, name, property_version);
        
        let token = token::withdraw_token(seller, token_id, 1);

        token::deposit_token(&resource_signer, token);
        // list_token_for_swap<CoinType>(&resource_signer, creator, collection, name, property_version, 1, price, 0);

        let offer_store = borrow_global_mut<SellOfferStore>(market_address);
        table::add(&mut offer_store.offers, token_id, SellOffer {
            market_id, seller: seller_addr, price
        });

        let guid = account::create_guid(&resource_signer);
        let market_events = borrow_global_mut<MarketEvents>(market_address);
        event::emit_event(&mut market_events.list_sell_token_events, ListSellTokenEvent{
            market_id, 
            token_id, 
            seller: seller_addr, 
            price, 
            timestamp: timestamp::now_microseconds(),
            offer_id: guid::creation_num(&guid)
        });
    }

    public entry fun delist_sell_token_offer<CoinType>(seller: &signer, market_address:address, market_name: String, creator: address, collection: String, name: String, property_version: u64) acquires MarketEvents, Market, SellOfferStore {
        let market_id = MarketId { market_name, market_address };
        let token_id = token::create_token_id_raw(creator, collection, name, property_version);
        let offer_store = borrow_global_mut<SellOfferStore>(market_address);
        let seller_store = table::borrow(&offer_store.offers, token_id).seller;
        let seller_addr = signer::address_of(seller);
        assert!(seller_addr == seller_store, ENO_AUTHROIZED_SELLER);
        
        let resource_signer = get_resource_account_cap(market_address);                
        let token = token::withdraw_token(&resource_signer, token_id, 1);
        token::deposit_token(seller, token);
        // token::direct_transfer(&resource_signer, seller, token_id, 1);
        table::remove(&mut offer_store.offers, token_id);    

        let market_events = borrow_global_mut<MarketEvents>(market_address);
        event::emit_event(&mut market_events.delist_sell_token_events, DeListSellTokenEvent{
            market_id,
            token_id,
            seller:seller_addr,
            timestamp: timestamp::now_microseconds(),            
        });    
    } 

    fun deduct_fee<CoinType>(
        total_coin: &mut Coin<CoinType>,
        fee_numerator: u64,
        fee_denominator: u64
    ): Coin<CoinType> {
        let value = coin::value(total_coin);
        let fee = if (fee_denominator == 0) {
            0
        } else {
            value * fee_numerator/ fee_denominator
        };
        coin::extract(total_coin, fee)
    }    

    public entry fun buy_token<CoinType>(buyer: &signer, market_address: address, market_name: String, creator: address, collection: String, name: String, property_version: u64, offer_id: u64) acquires MarketEvents, Market, SellOfferStore{
        let market_id = MarketId { market_name, market_address };
        let token_id = token::create_token_id_raw(creator, collection, name, property_version);
        let offer_store = borrow_global_mut<SellOfferStore>(market_address);
        let price = table::borrow(&offer_store.offers, token_id).price;
        let seller = table::borrow(&offer_store.offers, token_id).seller;
        let buyer_addr = signer::address_of(buyer);
        let required_balance = price;
        
        assert!(seller != buyer_addr, ESELLER_CAN_NOT_BE_BUYER);
        assert!(coin::balance<CoinType>(buyer_addr) >= required_balance, ENO_SUFFICIENT_FUND);

        let resource_signer = get_resource_account_cap(market_address);
        // let resource_signer_addr = signer::address_of(&resource_signer);
        // exchange_coin_for_token<CoinType>(buyer, price, signer::address_of(&resource_signer), creator, collection, name, property_version, 1);
                
        
        // send token from valut
        let token = token::withdraw_token(&resource_signer, token_id, 1);        
        token::deposit_token(buyer, token);

        // need coin from buyer and should be deducted    
        let coins = coin::withdraw<CoinType>(buyer, price);
    
        //royalty 2nd
        let royalty = token::get_royalty(token_id);
        let royalty_payee = token::get_royalty_payee(&royalty);
        let royalty_coin = deduct_fee<CoinType>(
            &mut coins,
            token::get_royalty_numerator(&royalty),
            token::get_royalty_denominator(&royalty)
        );
        coin::deposit(royalty_payee, royalty_coin);
        
        // marketfee deduction
        let market = borrow_global<Market>(market_address);
        let market_fee = price * market.fee_numerator / FEE_DENOMINATOR;
        let market_total_fee = coin::extract(&mut coins, market_fee);
        coin::deposit(market.fee_payee, market_total_fee);        
        
        // send back to seller left coins
        coin::deposit(seller, coins);

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
    // seller will sell nft, buyer offer will be matched with it and will be removed.
    public entry fun sell_token<CoinType>(seller: &signer, market_address: address, market_name: String, creator: address, collection: String, name: String, property_version: u64, offer_id: u64) acquires MarketEvents, Market, BuyOfferStore{
        let market_id = MarketId { market_name, market_address };        
        let offer_store = borrow_global_mut<BuyOfferStore>(market_address);
        let price = table::borrow(&offer_store.offers, offer_id).price;
        let buyer = table::borrow(&offer_store.offers, offer_id).buyer;
        let seller_addr = signer::address_of(seller);
        
        assert!(buyer != seller_addr, ESELLER_CAN_NOT_BE_BUYER);

        let resource_signer = get_resource_account_cap(market_address);

        let token_id = token::create_token_id_raw(creator, collection, name, property_version);        
        
        // send it to buyer
        token::transfer(seller, token_id, buyer, 1);

        // seller get money from vault        
        let coins = coin::withdraw<CoinType>(&resource_signer, price);
        // deduction royalty
        let royalty = token::get_royalty(token_id);
        let royalty_payee = token::get_royalty_payee(&royalty);
        let royalty_coin = deduct_fee<CoinType>(
            &mut coins,
            token::get_royalty_numerator(&royalty),
            token::get_royalty_denominator(&royalty)
        );
        coin::deposit(royalty_payee, royalty_coin);    
        
        // deduction market fee
        let market = borrow_global<Market>(market_address);
        let market_fee = price * market.fee_numerator / FEE_DENOMINATOR;
        let market_total_fee = coin::extract(&mut coins, market_fee);
        coin::deposit(market.fee_payee, market_total_fee);
        
        // send seller left
        coin::deposit(seller_addr, coins);
                
        table::remove(&mut offer_store.offers, offer_id);
        let market_events = borrow_global_mut<MarketEvents>(market_address);
        
        event::emit_event(&mut market_events.buy_token_events, BuyTokenEvent{
            market_id,
            token_id, 
            seller: seller_addr, 
            buyer, 
            price,
            timestamp: timestamp::now_microseconds(),
            offer_id
        });
    }
}