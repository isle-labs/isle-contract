build:
	forge build --contracts contracts/receivables/ReceivableStorage.sol
# --force --extra-output-files abi

test:
	forge test \
	--match-contract LopoPoolAssetTest \
	--match-test test_console \
	--contracts src/protocol-lite \
	-vvv 
# --chain-id 1337 \
--rpc-url ${GOERLI_RPC} \	
