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
  const sellerPrivateKey = '0x9271cae2621b9fe151992f34bf970b11d777fdb7373e34a48e9f4a8fcee4872d';
  const client = new WalletClient(APTOS_NODE_URL, APTOS_FAUCET_URL);
  const account = new AptosAccount(
    HexString.ensure(sellerPrivateKey).toUint8Array()
  );
  
  // seller: &signer, market_address:address, market_name: String, creator: address, collection: String, name: String, property_version: u64, new_price: u64
  const payload = {
    function: `${MARKET_ADDRESS}::marketplace::change_price`,
    type_arguments: [COIN_TYPE],
    arguments: [
      MARKET_ADDRESS,
      MARKET_NAME,
      "0x185479c6c8d8d649c9203938f322e783a11a3101006ee8c39ace252f99b9d155",
      "AptoPunks",
      "Punk #1854",
      "0",
      100000000,
    ],
  };
  console.log('lister:', account.address())
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
