<!-- init -->
NODE_ENV=development node create_market.mjs

<!-- listing -->
NODE_ENV=development node list_sell_token_offer.mjs
NODE_ENV=development node delist_sell_token_offer.mjs
NODE_ENV=development node query_listed_tokens.mjs
NODE_ENV=development node change_price.mjs

<!-- buy -->
NODE_ENV=development node buy_token.mjs

<!-- make / cancel offer on collection -->
NODE_ENV=development node list_collection_buy_token_offer.mjs
NODE_ENV=development node delist_collection_buy_token_offer.mjs
<!-- sell my nft to collection buy offer (instant sell) -->
NODE_ENV=development node sell_token_collection.mjs

<!-- make / cancel offer on token -->
NODE_ENV=development node list_buy_token_offer.mjs
NODE_ENV=development node delist_buy_token_offer.mjs
<!-- sell my nft to token buy offer (instant sell) -->
NODE_ENV=development node sell_token.mjs

<!-- gov token -->
NODE_ENV=development node deposit_gov_token.mjs
NODE_ENV=development node withdraw_gov_token.mjs

<!-- admin -->
NODE_ENV=development node admin_widthraw.mjs