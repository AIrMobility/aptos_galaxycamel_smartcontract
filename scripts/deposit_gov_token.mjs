import {
  AptosAccount,
  WalletClient,
  AptosClient,
  TokenClient,
  HexString,
} from "@martiandao/aptos-web3-bip44.js";
import * as env from "dotenv";
env.config({ path: `.env.${process.env.NODE_ENV}.local` });

const {
  NEXT_PUBLIC_APTOS_NODE_URL: APTOS_NODE_URL,
  NEXT_PUBLIC_APTOS_FAUCET_URL: APTOS_FAUCET_URL,
  NEXT_PUBLIC_WALLET_PRIVATE_KEY: WALLET_PRIVATE_KEY,
  NEXT_PUBLIC_MARKET_COIN_TYPE: COIN_TYPE,
  NEXT_PUBLIC_MARKET_ADDRESS: MARKET_ADDRESS,
  NEXT_PUBLIC_MARKET_NAME: MARKET_NAME,
} = process.env;

async function main() {
  const client = new WalletClient(APTOS_NODE_URL, APTOS_FAUCET_URL);
  const aptosClient = new AptosClient(APTOS_NODE_URL);
  const tokenClient = new TokenClient(aptosClient);
  //
  const account = new AptosAccount(
    HexString.ensure(WALLET_PRIVATE_KEY).toUint8Array() // TOKEN OWNER = MARKET DEPLOYER
  );
  // deposit_gov_token
  // (govener: &signer, creator: address, collection: String, name: String, property_version: u64, amount:u64)
  const payload = {
    function: `${MARKET_ADDRESS}::marketplace::deposit_gov_token`,
    type_arguments: [],
    arguments: [
      account.address(),
      "Camel Token",
      "Camel Token",
      0,
      1000000
    ],
  };
  const transaction = await client.aptosClient.generateTransaction(
    account.address(),
    payload,
    { gas_unit_price: 100 }
  );
  const tx = await client.signAndSubmitTransaction(account, transaction);
  const result = await client.aptosClient.waitForTransactionWithResult(tx, {
    checkSuccess: true,
  });
  console.log(tx)
  console.log(result)
  // console.log(result.vm_status);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
