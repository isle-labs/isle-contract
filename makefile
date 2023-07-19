build:
	forge build --contracts contracts/globals/lopoGlobals.sol
# --force --extra-output-files abi

test:
	forge test \
	--contracts contracts/receivable/receivable \
	--match-contract ReceivableTest \
	--match-test test_console \
	-vvv 


# --chain-id 1337 \
--rpc-url ${GOERLI_RPC} \	
