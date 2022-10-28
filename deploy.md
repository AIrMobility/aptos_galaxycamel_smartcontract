# for first step
aptos init
aptos account fund-with-faucet --account default

# normal

aptos move compile --named-addresses galaxycamel=default
aptos move publish --named-addresses galaxycamel=default

# test case
aptos move test --named-addresses galaxycamel=default

# addr
pk=0xa98f5cd84cb454d5f4538e8cb26c62e5c5fdb1797d25ef9c22f0d07bcf352d39
pub_addr=0x7193d384732aff0c048eded1ac8e62d8492f12cf28b9e0b85245cf760c095512
sender=2786201547f747caa505ce8833118f5fd01c978d23d607570759cd298aa70d7f
# test function
aptos move run \
  --function-id '2786201547f747caa505ce8833118f5fd01c978d23d607570759cd298aa70d7f::marketplace::create_market' \
  --args 'address:0x1c59cef21f1e2d41181669a4b33a93d7614e524120ac2fceabc9cb0cba8be9e6 string:testmarket u64:100 address:0x1c59cef21f1e2d41181669a4b33a93d7614e524120ac2fceabc9cb0cba8be9e6 u64:1'
  --private-key '0xa98f5cd84cb454d5f4538e8cb26c62e5c5fdb1797d25ef9c22f0d07bcf352d39'
