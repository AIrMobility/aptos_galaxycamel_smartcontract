import {
  AptosAccount,
  WalletClient,
  HexString,
} from "@martiandao/aptos-web3-bip44.js";
import * as env from "dotenv";
env.config({ path: `.env.${process.env.NODE_ENV}.local` });

const {
  NEXT_PUBLIC_APTOS_NODE_URL: APTOS_NODE_URL,
  NEXT_PUBLIC_APTOS_FAUCET_URL: APTOS_FAUCET_URL,
  NEXT_PUBLIC_WALLET_PRIVATE_KEY: ARBITRAGER_PRIVATE_KEY,
  NEXT_PUBLIC_MARKET_COIN_TYPE: COIN_TYPE,
  NEXT_PUBLIC_MARKET_ADDRESS: MARKET_ADDRESS,
  NEXT_PUBLIC_MARKET_NAME: MARKET_NAME,
} = process.env;

async function main() {
  const buyerPrivateKey = '0x721f206838104aa972211be79f84d5548ad7fec8593c51c01e9ae793a228f716';
  const client = new WalletClient(APTOS_NODE_URL, APTOS_FAUCET_URL);
  const account = new AptosAccount(
    HexString.ensure(buyerPrivateKey).toUint8Array()
  );
  
  console.log('MARKET_ADDRESS:', MARKET_ADDRESS)
  // (buyer: &signer, market_address:address, market_name: String, creator: address, collection: String, name: String, property_version: u64, offer_id: u64)
  const payload = {
    function: `${MARKET_ADDRESS}::marketplace::delist_buy_token_offer`,
    type_arguments: [COIN_TYPE],
    arguments: [
      MARKET_ADDRESS,
      MARKET_NAME,
      "0x157ff13da599009db8f81b3981ed8e53b0a9bdc926045f54a2877f646901a169",
      "Elp nose",
      "Nose #45",
      0,
      15,
    ],
  };
  console.log('delister:', account.address())
  const transaction = await client.aptosClient.generateTransaction(
    account.address(),
    payload,
    { gas_unit_price: 100 }
  );
  const tx = await client.signAndSubmitTransaction(account, transaction);
  const result = await client.aptosClient.waitForTransactionWithResult(tx, {
    checkSuccess: true,
  });
  console.log(result);
  // console.log(result.vm_status);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
