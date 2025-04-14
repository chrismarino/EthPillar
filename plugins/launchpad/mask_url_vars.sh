# Define the file path
#FILE="$LAUNCHPAD_SOURCE_DIR/src/utils/envVars.ts"
FILE="/home/chris/git/staking-launchpad/src/utils/envVars.ts"

# Add a comment above the MAINNET_LAUNCHPAD_URL line
sed -i '/export const MAINNET_LAUNCHPAD_URL/i // EthPillar Launchpad Plugin installation Changed these vars. They are now both set to empty string' "$FILE"

# Set the MAINNET_LAUNCHPAD_URL to hoodi.launchpad.$(hostname)
sed -i '/export const MAINNET_LAUNCHPAD_URL/c\export const MAINNET_LAUNCHPAD_URL = ``;' "$FILE"

# Set the TESTNET_LAUNCHPAD_URL to hoodi.launchpad.$(hostname)
sed -i '/export const TESTNET_LAUNCHPAD_URL/c\export const TESTNET_LAUNCHPAD_URL = ``;' "$FILE"

# Print a success message
echo "Successfully blanked out MAINNET_LAUNCHPAD_URL and TESTNET_LAUNCHPAD_URLs in $FILE"