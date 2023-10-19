#!/usr/bin/bash
forge test --gas-report | tee >(grep '^|' > .gas-report)
