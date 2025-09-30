#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

generate_uuid() {
    if command -v uuidgen &> /dev/null; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    elif command -v python3 &> /dev/null; then
        python3 -c "import uuid; print(str(uuid.uuid4()))"
    else
        hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/urandom | sed 's/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1\2\3\4-\5\6-\7\8-\9\10-\11\12\13\14\15\16/' | tr '[:upper:]' '[:lower:]'
    fi
}

clear

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Python Xray Argo One-Click Deployment Script    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo -e "${GREEN}This script is developed based on eooce's Python Xray Argo project${NC}"
echo -e "${GREEN}Provides both quick and full configuration modes to simplify deployment${NC}"
echo -e "${GREEN}Supports automatic UUID generation, background running, and node information output${NC}"
echo

echo -e "${YELLOW}Please select configuration mode:${NC}"
echo -e "${BLUE}1) Quick Mode - Only modify UUID and start${NC}"
echo -e "${BLUE}2) Full Mode - Configure all options in detail${NC}"
echo
read -p "Enter your choice (1/2): " MODE_CHOICE

echo -e "${BLUE}Checking and installing dependencies...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}Installing Python3...${NC}"
    sudo apt-get update && sudo apt-get install -y python3 python3-pip
fi

if ! python3 -c "import requests" &> /dev/null; then
    echo -e "${YELLOW}Installing Python dependencies...${NC}"
    pip3 install requests
fi

PROJECT_DIR="/tmp/.cache"
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${BLUE}Creating project directory...${NC}"
    mkdir -p "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"

echo -e "${BLUE}Downloading full repository...${NC}"
if [ ! -f "app.py" ]; then
    if command -v git &> /dev/null; then
        echo -e "${YELLOW}Using git to clone repository...${NC}"
        git clone https://github.com/eooce/python-xray-argo.git /tmp/python-xray-argo-temp
        cp -r /tmp/python-xray-argo-temp/* "$PROJECT_DIR"/
        rm -rf /tmp/python-xray-argo-temp
    else
        echo -e "${YELLOW}Git not installed, using wget to download...${NC}"
        wget -q https://github.com/eooce/python-xray-argo/archive/refs/heads/main.zip -O /tmp/python-xray-argo.zip
        if command -v unzip &> /dev/null; then
            unzip -q /tmp/python-xray-argo.zip -d /tmp/
            cp -r /tmp/python-xray-argo-main/* "$PROJECT_DIR"/
            rm -rf /tmp/python-xray-argo-main /tmp/python-xray-argo.zip
        else
            echo -e "${YELLOW}Installing unzip...${NC}"
            sudo apt-get install -y unzip
            unzip -q /tmp/python-xray-argo.zip -d /tmp/
            cp -r /tmp/python-xray-argo-main/* "$PROJECT_DIR"/
            rm -rf /tmp/python-xray-argo-main /tmp/python-xray-argo.zip
        fi
    fi
fi

if [ $? -ne 0 ] || [ ! -f "app.py" ]; then
    echo -e "${RED}Download failed or app.py not found, please check your network connection${NC}"
    echo -e "${YELLOW}Trying alternative download method...${NC}"
    
    # Alternative direct download
    wget -q https://raw.githubusercontent.com/eooce/python-xray-argo/main/app.py -O app.py
    wget -q https://raw.githubusercontent.com/eooce/python-xray-argo/main/requirements.txt -O requirements.txt 2>/dev/null || true
    
    if [ ! -f "app.py" ]; then
        echo -e "${RED}Failed to download app.py${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Dependencies installed successfully!${NC}"
echo

if [ ! -f "app.py" ]; then
    echo -e "${RED}app.py file not found!${NC}"
    echo -e "${YELLOW}Files in $PROJECT_DIR:${NC}"
    ls -la "$PROJECT_DIR"
    exit 1
fi

# Install requirements if exists
if [ -f "requirements.txt" ]; then
    echo -e "${YELLOW}Installing Python requirements...${NC}"
    pip3 install -r requirements.txt
fi

cp app.py app.py.backup
echo -e "${YELLOW}Original file backed up as app.py.backup${NC}"

if [ "$MODE_CHOICE" = "1" ]; then
    echo -e "${BLUE}=== Quick Mode ===${NC}"
    echo
    
    CURRENT_UUID=$(grep "UUID = " app.py | head -1 | cut -d"'" -f2 2>/dev/null || echo "not found")
    echo -e "${YELLOW}Current UUID: $CURRENT_UUID${NC}"
    read -p "Enter new UUID (leave empty to auto-generate): " UUID_INPUT
    if [ -z "$UUID_INPUT" ]; then
        UUID_INPUT=$(generate_uuid)
        echo -e "${GREEN}Auto-generated UUID: $UUID_INPUT${NC}"
    fi
    
    # Update UUID in app.py
    if grep -q "UUID = os.environ.get('UUID'," app.py; then
        sed -i "s/UUID = os.environ.get('UUID', '[^']*')/UUID = os.environ.get('UUID', '$UUID_INPUT')/" app.py
    else
        # If the pattern doesn't exist, add it
        echo "UUID = os.environ.get('UUID', '$UUID_INPUT')" >> app.py
    fi
    echo -e "${GREEN}UUID set to: $UUID_INPUT${NC}"
    
    # Update CFIP
    if grep -q "CFIP = os.environ.get('CFIP'," app.py; then
        sed -i "s/CFIP = os.environ.get('CFIP', '[^']*')/CFIP = os.environ.get('CFIP', 'kick.com')/" app.py
    else
        echo "CFIP = os.environ.get('CFIP', 'kick.com')" >> app.py
    fi
    echo -e "${GREEN}Optimized IP automatically set to: kick.com${NC}"
    
    echo
    echo -e "${GREEN}Quick configuration complete! Starting service...${NC}"
    echo
    
else
    echo -e "${BLUE}=== Full Configuration Mode ===${NC}"
    echo
    
    CURRENT_UUID=$(grep "UUID = " app.py | head -1 | cut -d"'" -f2 2>/dev/null || echo "not found")
    echo -e "${YELLOW}Current UUID: $CURRENT_UUID${NC}"
    read -p "Enter new UUID (leave empty to auto-generate): " UUID_INPUT
    if [ -z "$UUID_INPUT" ]; then
        UUID_INPUT=$(generate_uuid)
        echo -e "${GREEN}Auto-generated UUID: $UUID_INPUT${NC}"
    fi
    
    if grep -q "UUID = os.environ.get('UUID'," app.py; then
        sed -i "s/UUID = os.environ.get('UUID', '[^']*')/UUID = os.environ.get('UUID', '$UUID_INPUT')/" app.py
    else
        echo "UUID = os.environ.get('UUID', '$UUID_INPUT')" >> app.py
    fi
    echo -e "${GREEN}UUID set to: $UUID_INPUT${NC}"

    # ... (rest of the full configuration mode remains the same)
fi

echo -e "${YELLOW}=== Current Configuration Summary ===${NC}"
echo -e "UUID: $(grep "UUID = " app.py | head -1 | cut -d"'" -f2 2>/dev/null || echo "not found")"
echo -e "${YELLOW}========================${NC}"
echo

echo -e "${BLUE}Starting service...${NC}"
echo -e "${YELLOW}Current working directory: $(pwd)${NC}"
echo -e "${YELLOW}Files in directory:${NC}"
ls -la

echo
nohup python3 app.py > app.log 2>&1 &
APP_PID=$!

echo -e "${GREEN}Service started in background, PID: $APP_PID${NC}"
echo -e "${YELLOW}Log file: $(pwd)/app.log${NC}"

echo -e "${BLUE}Waiting for service to start...${NC}"
sleep 10

if ps -p $APP_PID > /dev/null; then
    echo -e "${GREEN}Service running normally${NC}"
else
    echo -e "${RED}Service failed to start, please check logs${NC}"
    echo -e "${YELLOW}View logs: tail -f app.log${NC}"
    echo -e "${YELLOW}Last few lines of log:${NC}"
    tail -20 app.log
    exit 1
fi

SERVICE_PORT=$(grep "PORT = int" app.py | grep -o "or [0-9]*" | cut -d" " -f2 2>/dev/null || echo "8080")
CURRENT_UUID=$(grep "UUID = " app.py | head -1 | cut -d"'" -f2 2>/dev/null || echo "not-found")
SUB_PATH_VALUE=$(grep "SUB_PATH = " app.py | cut -d"'" -f4 2>/dev/null || echo "sub")

echo -e "${BLUE}Waiting for node information generation...${NC}"
sleep 15

NODE_INFO=""
if [ -f ".cache/sub.txt" ]; then
    NODE_INFO=$(cat .cache/sub.txt)
elif [ -f "sub.txt" ]; then
    NODE_INFO=$(cat sub.txt)
fi

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}           Deployment Complete!         ${NC}"
echo -e "${GREEN}========================================${NC}"
echo

echo -e "${YELLOW}=== Service Information ===${NC}"
echo -e "Service Status: ${GREEN}Running${NC}"
echo -e "Process PID: ${BLUE}$APP_PID${NC}"
echo -e "Service Port: ${BLUE}$SERVICE_PORT${NC}"
echo -e "UUID: ${BLUE}$CURRENT_UUID${NC}"
echo -e "Subscription Path: ${BLUE}/$SUB_PATH_VALUE${NC}"
echo

echo -e "${YELLOW}=== Access URLs ===${NC}"
if command -v curl &> /dev/null; then
    PUBLIC_IP=$(curl -s -m 5 https://api.ipify.org 2>/dev/null || echo "Failed to get")
    if [ "$PUBLIC_IP" != "Failed to get" ]; then
        echo -e "Subscription URL: ${GREEN}http://$PUBLIC_IP:$SERVICE_PORT/$SUB_PATH_VALUE${NC}"
        echo -e "Admin Panel: ${GREEN}http://$PUBLIC_IP:$SERVICE_PORT${NC}"
    fi
fi
echo -e "Local Subscription: ${GREEN}http://localhost:$SERVICE_PORT/$SUB_PATH_VALUE${NC}"
echo -e "Local Admin Panel: ${GREEN}http://localhost:$SERVICE_PORT${NC}"
echo

if [ -n "$NODE_INFO" ]; then
    echo -e "${YELLOW}=== Node Information ===${NC}"
    echo -e "${GREEN}Subscription Link (Base64 Encoded):${NC}"
    echo "$NODE_INFO"
    echo
else
    echo -e "${YELLOW}=== Node Information ===${NC}"
    echo -e "${RED}Node information not generated yet, please wait a few minutes and check logs or manually access subscription URL${NC}"
    echo
fi

echo -e "${YELLOW}=== Management Commands ===${NC}"
echo -e "View logs: ${BLUE}tail -f $(pwd)/app.log${NC}"
echo -e "Stop service: ${BLUE}kill $APP_PID${NC}"
echo -e "Restart service: ${BLUE}kill $APP_PID && nohup python3 app.py > app.log 2>&1 &${NC}"
echo -e "View processes: ${BLUE}ps aux | grep python3${NC}"
echo

echo -e "${YELLOW}=== Important Notes ===${NC}"
echo -e "${GREEN}Service is running in background, please wait for Argo tunnel to establish${NC}"
echo -e "${GREEN}If using temporary tunnel, domain will appear in logs after a few minutes${NC}"
echo -e "${GREEN}Recommended to check subscription URL again after 10-15 minutes for latest node info${NC}"
echo -e "${GREEN}Check logs for detailed startup process and tunnel information${NC}"
echo

echo -e "${GREEN}Deployment complete! Thank you for using!${NC}"
