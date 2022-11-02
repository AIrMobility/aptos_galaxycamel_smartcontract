import { AptosClient } from "aptos";
import * as env from "dotenv";
env.config({ path: `.env.${process.env.NODE_ENV}.local` });

const {
  NEXT_PUBLIC_APTOS_NODE_URL: APTOS_NODE_URL,
  NEXT_PUBLIC_MARKET_ADDRESS: MARKET_ADDRESS,
} = process.env;

async function main() {
  const filterObj = {}
  const client = new AptosClient(APTOS_NODE_URL);
  const listEvents = await client.getEventsByEventHandle(
    MARKET_ADDRESS,
    `${MARKET_ADDRESS}::marketplace::MarketEvents`,
    'list_token_events',
    { start: 0n + 1n, limit: 100 }
  );
  listEvents.sort((a,b) => Number(b.data.timestamp) - Number(a.data.timestamp))
  console.log('listEvents:', listEvents.length)

  const delistEvents = await client.getEventsByEventHandle(
    MARKET_ADDRESS,
    `${MARKET_ADDRESS}::marketplace::MarketEvents`,
    'delist_token_events',
    { start: 0n + 1n, limit: 100 }
  );
  delistEvents.sort((a,b) => Number(b.data.timestamp) - Number(a.data.timestamp))
  console.log('delistEvents:', delistEvents.length)
  if (delistEvents.length) {
    delistEvents.forEach(el => {
      const uuid = JSON.stringify(el.data.token_id.token_data_id);
      console.log("Delisted:", uuid);
      filterObj[uuid] = Number(el.data.timestamp);
    });
  }
  const buyEvents = await client.getEventsByEventHandle(
    MARKET_ADDRESS,
    `${MARKET_ADDRESS}::marketplace::MarketEvents`,
    'buy_token_events',
    { start: 0n + 1n, limit: 100 }
  );
  buyEvents.sort((a,b) => Number(b.data.timestamp) - Number(a.data.timestamp))
  console.log('buyEvents:', buyEvents.length)
  if (buyEvents.length) {
    buyEvents.forEach(el => {
      const uuid = JSON.stringify(el.data.token_id.token_data_id);
      console.log("Bought:", uuid);
      filterObj[uuid] = Number(el.data.timestamp);
    });
  }

  const finalListedItems = [];
  listEvents.forEach(el => {
    const uuid = JSON.stringify(el.data.token_id.token_data_id);
    console.log("Listed token:", uuid);
    if (Object.keys(filterObj).length) {
      const listEventTimestamp = Number(el.data.timestamp);
      const buyOrDelistEventTimestamp = filterObj[uuid];
      if (!buyOrDelistEventTimestamp || listEventTimestamp > buyOrDelistEventTimestamp) {
        finalListedItems.push(el.data);
      }
    }
  })
  console.log("data:", listEvents[0].data);
  // console.log('finalListedItems:', finalListedItems)
  // console.log('finalListedItems:', finalListedItems.map(el => el.token_id.token_data_id))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
