#!/bin/bash

# Base directory with scripts
BASE_DIR=$HOME/git/ethpillar

# Load functions
source $BASE_DIR/functions.sh

# Load environment variables, Lido CSM withdrawal address and fee recipient
source $BASE_DIR/env
getNetwork  # This sets the NETWORK variable
# Get machine info
_platform=$(get_platform)
_network=$(get_network)
_arch=$(get_arch)

# Variables
DESCRIPTION="Ethereum Launchpad for Validator Deposits and Other Actions"
DOCUMENTATION="http://eth.coincashew.com"
SOURCE_CODE="https://github.com/coincashew/ethpillar"
PLUGIN_NAME="Ethereum Launchpad"
LAUNCHPAD_GITHUP_REPO_URL="https://github.com/ethereum/staking-launchpad.git"
BRANCH="dev"
LAUNCHPAD_SOURCE_DIR="$HOME/git/staking-launchpad" # install repo next to ethpillar for now
PLUGIN_PATH=$BASE_DIR/plugins/launchpad
export LAUNCHPAD_BUILD_DIR="/opt/ethpillar/plugin-launchpad"
TESTNET_ENV_VARS_FILE="hoodi_launchpad_env_vars" # Not sure if this is needed
MAINNET_ENV_VARS_FILE="mainnet_launchpad_env_vars" # Not sure if this is needed


#Asks to update
function _upgradePlugin(){
    ohai "Not implimented yet"
}

# Uninstall
function _removePlugin() {
	if whiptail --title "Uninstall $PLUGIN_NAME" --defaultno --yesno "Are you sure you want to remove $PLUGIN_NAME" 9 78; then
	  sudo rm -rf "$LAUNCHPAD_BUILD_DIR"
    sudo rm -rf "$LAUNCHPAD_SOURCE_DIR"
  	whiptail --title "Uninstall finished" --msgbox "You have uninstalled $PLUGIN_NAME. Leaving node, nvm, yarn and serve installed" 8 78
	fi
}
# Clone the repo
function _cloneRepo(){
		#Download and installbinaries
		echo Cloneing repo: $LAUNCHPAD_GITHUP_REPO_URL
		cd $HOME
    ohai "Cloning Launchpad into $LAUNCHPAD_SOURCE_DIR"
    mkdir -p $LAUNCHPAD_SOURCE_DIR
    echo "Cloning repo: $LAUNCHPAD_GITHUP_REPO_URL into $LAUNCHPAD_SOURCE_DIR"
    git clone $LAUNCHPAD_GITHUP_REPO_URL $LAUNCHPAD_SOURCE_DIR 2> /dev/null
    cd $LAUNCHPAD_SOURCE_DIR ; git fetch origin $BRANCH ; git checkout $BRANCH ; git pull
    exit_on_error $?
}
# Create the .env file
function _setEnvVars(){
  case $_network in
      Mainnet)
        ohai "Creating .env for mainnet: cat \"${PLUGIN_PATH}/$MAINNET_ENV_VARS_FILE\" > \"${LAUNCHPAD_SOURCE_DIR}/.env\""
        cat "${PLUGIN_PATH}/$MAINNET_ENV_VARS_FILE" > "${LAUNCHPAD_SOURCE_DIR}/.env"
        HOST=$(hostname -I | awk '{print $1}') # Get the host's IP address
        REACT_APP_RPC_URL="http://$HOST:8545" # would https://localhost:8545 work?
        echo "REACT_APP_RPC_URL=$REACT_APP_RPC_URL" >> "${LAUNCHPAD_SOURCE_DIR}/.env"
        REACT_APP_BEACONCHAIN_URL="http://$HOST:5052" # would https://localhost:8545 work?
        echo "REACT_APP_BEACONCHAIN_URL=$REACT_APP_BEACONCHAIN_URL" >> "${LAUNCHPAD_SOURCE_DIR}/.env"
      ;;
      Hoodi)
        ohai "Creating .env for testnet: cat \"${PLUGIN_PATH}/$TESTNET_ENV_VARS_FILE\" > \"${LAUNCHPAD_SOURCE_DIR}/.env\""
        cat "${PLUGIN_PATH}/$TESTNET_ENV_VARS_FILE" > "${LAUNCHPAD_SOURCE_DIR}/.env"
        HOST=$(hostname -I | awk '{print $1}') # Get the host's IP address
        REACT_APP_RPC_URL="http://$HOST:8545" # would https://localhost:8545 work?
        echo "REACT_APP_RPC_URL=$REACT_APP_RPC_URL" >> "${LAUNCHPAD_SOURCE_DIR}/.env"
        REACT_APP_BEACONCHAIN_URL="http://$HOST:5052" # would https://localhost:8545 work?
        echo "REACT_APP_BEACONCHAIN_URL=$REACT_APP_BEACONCHAIN_URL" >> "${LAUNCHPAD_SOURCE_DIR}/.env"
      ;;
        "Network Syncing")
        echo "Network still sycning. Try again later."
        # Added for testing on nodes that are not synced
        # ohai "Creating .env for testnet: cat \"${PLUGIN_PATH}/$TESTNET_ENV_VARS_FILE\" > \"${LAUNCHPAD_SOURCE_DIR}/.env\""
        # cat "${PLUGIN_PATH}/$TESTNET_ENV_VARS_FILE" > "${LAUNCHPAD_SOURCE_DIR}/.env"
      ;;
      *)
        echo $_network
        echo "Error: Unsupported network. Please use mainnet or hoodi."
        exit 1
      ;;
  esac
}
# Install Node and clone the repo
function _doInstall(){
  # Clone the Launchpad repo
  _cloneRepo
  # Install node, nvm and set to version 16
  echo "Installing Node.js and NVM..."
  cd $PLUGIN_PATH
  $PLUGIN_PATH/node_install.sh
  # Mask the URL VARs in the source code
  $PLUGIN_PATH/mask_url_vars.sh
  _setEnvVars
}

# Build the plugin
function _doBuild(){
  cd $LAUNCHPAD_SOURCE_DIR
  # Load nvm
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

  # Use Node.js version 16
  ohai "Building Launchpad..."
  echo "Setting Node.js version to 16..."
  nvm use 16

  # Verify Node.js and npm installation
  echo "Node.js version: $(node -v)"
  echo "npm version: $(npm -v)"
  yarn
  yarn build
}
# Deploy the plugin
function _doDeploy(){
    # Check if the Launchpad directory exists
  if [ ! -d "$LAUNCHPAD_SOURCE_DIR/build" ]; then
    echo "Launchpad not installed. Please install then try again."
    exit 1
  fi
  ohai "Deploying Launchpad to $LAUNCHPAD_BUILD_DIR"
  sudo mkdir -p $LAUNCHPAD_BUILD_DIR
  sudo chown -R $USER:$USER $LAUNCHPAD_BUILD_DIR
  cd $LAUNCHPAD_SOURCE_DIR
  sudo cp -r build $LAUNCHPAD_BUILD_DIR
  _doStart
}
function _doStart(){
  # Check if the Launchpad directory exists
  if [ ! -d "$LAUNCHPAD_BUILD_DIR/build" ]; then
    echo "Launchpad not built is missing or not complete. Please install then try again." 
    exit 1
  fi
  ohai "Starting Launchpad"
  cd $LAUNCHPAD_BUILD_DIR
  # Start the plugin with sudo, log PID and errors
  serve -L -p 8080 build > "$LAUNCHPAD_BUILD_DIR/serve.log" 2>&1 & echo $! > "$LAUNCHPAD_BUILD_DIR/serve.pid"
  
  # Display a whiptail message
  HOST=$(hostname -I | awk '{print $1}') # Get the host's IP address
  whiptail --title "Launchpad Started" --msgbox "Available at - \nhttp://$HOSTNAME:8080 \nhttp://$HOST:8080" 10 60
}
function _doStop(){
  # Check if the Launchpad directory exists
  if [ ! -d "$LAUNCHPAD_BUILD_DIR/build" ]; then
    echo "Launchpad not built is missing or not complete. Please install then try again."
    exit 1
  fi

  # Stop the plugin using the PID, redirect errors to error.log
  if [ -f "$LAUNCHPAD_BUILD_DIR/serve.pid" ]; then
    PID=$(cat "$LAUNCHPAD_BUILD_DIR/serve.pid")
    if kill -0 "$PID" 2>/dev/null; then
      ohai "Stopping Launchpad (PID: $PID)"
      kill "$PID" 2>> "$LAUNCHPAD_BUILD_DIR/error.log"
      rm -f "$LAUNCHPAD_BUILD_DIR/serve.pid"
    else
      echo "No running serve process found with PID: $PID"
      rm -f "$LAUNCHPAD_BUILD_DIR/serve.pid"
    fi
  else
    echo "No PID file found. Serve process may not be running."
  fi
}
function _editConfig(){
  # Check if the Launchpad directory exists
  if [ ! -d "$LAUNCHPAD_BUILD_DIR/build" ]; then
    echo "Launchpad not built is missing or not complete. Please install then try again."
    exit 1
  fi
  # Edit the config file
  cd $LAUNCHPAD_BUILD_DIR
  nano .env
}
function _installPlugin(){

    MSG_CONFIRM="\nInstalling the Ethereum Launchpad for the ${_network}.
  \nThis is a locally hosted app to make Ethereum deposits and perform other post-Pectra actions. It should only be accessable on your local network from clients that you trust.
  \nRunning the Launchpad required Node v16, NVM and serve. This script will install them if they are not already installed.
  \nIMPORTANT: BE SURE YOU UNDERSTAND THE USE AND LIMITATIONS OF THIS LAUNCHPAD.
  
 \nONLY INSTALL ON A LOCAL NETWORK THAT YOU TRUST.  
 \nIT DOES NOT USE HPPTS: Communications from the Launchpad running in your browser to your EthPillar node will be unencypted cleartext.
 \nWait until after the node is fully synced before installing the Launchpad Plugin.
 \n\nDo you want to continue?"

  if whiptail --title "Confirm Install" --defaultno --yesno "$MSG_CONFIRM" 30  78; then
      _doInstall
      _doBuild
      _doDeploy
  fi  
}   



# Displays usage info
function usage() {
cat << EOF
Usage: $(basename "$0") [-i] [-s] [-x] [-e] [-u] [-r] [-h]

$PLUGIN_NAME Helper Script

Options)
-i    Install $PLUGIN_NAME
-s    Start $PLUGIN_NAME
-x    Stop $PLUGIN_NAME
-e    Edit $PLUGIN_NAME configuration
-u    Upgrade $PLUGIN_NAME
-r    Remove $PLUGIN_NAME
-h    Display help

About $PLUGIN_NAME)
- $DESCRIPTION
- Source code: $SOURCE_CODE
- Documentation: $DOCUMENTATION
EOF
}

setWhiptailColors

# Process command line options
while getopts :isxeurth opt; do
  case ${opt} in
    i ) _installPlugin ;;
    s ) _doStart ;;
    x ) _doStop ;;
    e ) _editConfig ;;
    u ) _upgradePlugin ;;
    r ) _removePlugin ;;
    h )
      usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      usage
      exit 1
      ;;
    :)
      echo "Option -${OPTARG} requires an argument." >&2
      usage
      exit 1
      ;;
  esac
done
