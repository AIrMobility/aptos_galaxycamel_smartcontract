import {
  AptosAccount,
  WalletClient,
  HexString,
} from "@martiandao/aptos-web3-bip44.js";
import * as env from "dotenv";
env.config({ path: `.env.${process.env.NODE_ENV}.local` });
console.log('process.env.NODE_ENV:', process.env.NODE_ENV)

const {
  NEXT_PUBLIC_APTOS_NODE_URL: APTOS_NODE_URL,
  NEXT_PUBLIC_APTOS_FAUCET_URL: APTOS_FAUCET_URL,
  NEXT_PUBLIC_WALLET_PRIVATE_KEY: WALLET_PRIVATE_KEY,
  NEXT_PUBLIC_MARKET_COIN_TYPE: COIN_TYPE,
  NEXT_PUBLIC_MARKET_NAME: MARKET_NAME,
  NEXT_PUBLIC_MARKET_FEE_NUMERATOR: FEE_NUMERATOR,
  NEXT_PUBLIC_MARKET_INITIAL_FUND: INITIAL_FUND,
} = process.env;

async function main() {
  const marketDeployer = WALLET_PRIVATE_KEY;
  const client = new WalletClient(APTOS_NODE_URL, APTOS_FAUCET_URL);
  const account = new AptosAccount(
    HexString.ensure(marketDeployer).toUint8Array()
  );
  console.log('FEE_NUMERATOR:', FEE_NUMERATOR)
  console.log('INITIAL_FUND:', INITIAL_FUND)
  console.log('function:', `${account.address()}::marketplace::create_market`)
  // (sender: &signer, market_name: String, fee_numerator: u64, fee_payee: address, initial_fund: u64, gov_token_creator: address, gov_token_collection: String, token_gov_token_name: String , gov_token_property_version:u64)
  const payload = {
    function: `${account.address()}::marketplace::create_market`,
    type_arguments: [COIN_TYPE],
    arguments: [
      MARKET_NAME,
      +FEE_NUMERATOR,
      account.address(),
      +INITIAL_FUND,
      account.address(),
      'Camel Token',
      'Camel Token',
      0,
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
  console.log(result);
  
  client.signTransaction
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
