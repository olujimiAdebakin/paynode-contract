#!/bin/bash
# scripts/test.sh

echo "Running PayNode Contract Tests..."

# Run all tests
forge test --vvv

# Run specific test contracts
# forge test --match-contract PGatewaySettingsTest -vv
# forge test --match-contract PGatewayTest -vv

# Run with gas reports
# forge test --gas-report