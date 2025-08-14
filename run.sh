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

PROJECT_DIR=".sys_info"
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${BLUE}Downloading full repository...${NC}"
    if command -v git &> /dev/null; then
        git clone https://github.com/eooce/python-xray-argo.git
    else
        echo -e "${YELLOW}Git not installed, using wget to download...${NC}"
        wget -q https://github.com/eooce/python-xray-argo/archive/refs/heads/main.zip -O python-xray-argo.zip
        if command -v unzip &> /dev/null; then
            unzip -q python-xray-argo.zip
            mv python-xray-argo-main .sys_info
            rm python-xray-argo.zip
        else
            echo -e "${YELLOW}Installing unzip...${NC}"
            sudo apt-get install -y unzip
            unzip -q python-xray-argo.zip
            mv python-xray-argo-main .sys_info
            rm python-xray-argo.zip
        fi
    fi
    
    if [ $? -ne 0 ] || [ ! -d "$PROJECT_DIR" ]; then
        echo -e "${RED}Download failed, please check your network connection${NC}"
        exit 1
    fi
fi

cd "$PROJECT_DIR"

echo -e "${GREEN}Dependencies installed successfully!${NC}"
echo

if [ ! -f "app.py" ]; then
    echo -e "${RED}app.py file not found!${NC}"
    exit 1
fi

cp app.py app.py.backup
echo -e "${YELLOW}Original file backed up as app.py.backup${NC}"

if [ "$MODE_CHOICE" = "1" ]; then
    echo -e "${BLUE}=== Quick Mode ===${NC}"
    echo
    
    echo -e "${YELLOW}Current UUID: $(grep "UUID = " app.py | head -1 | cut -d"'" -f2)${NC}"
    read -p "Enter new UUID (leave empty to auto-generate): " UUID_INPUT
    if [ -z "$UUID_INPUT" ]; then
        UUID_INPUT=$(generate_uuid)
        echo -e "${GREEN}Auto-generated UUID: $UUID_INPUT${NC}"
    fi
    
    sed -i "s/UUID = os.environ.get('UUID', '[^']*')/UUID = os.environ.get('UUID', '$UUID_INPUT')/" app.py
    echo -e "${GREEN}UUID set to: $UUID_INPUT${NC}"
    
    sed -i "s/CFIP = os.environ.get('CFIP', '[^']*')/CFIP = os.environ.get('CFIP', 'kick.com')/" app.py
    echo -e "${GREEN}Optimized IP automatically set to: kick.com${NC}"
    
    echo
    echo -e "${GREEN}Quick configuration complete! Starting service...${NC}"
    echo
    
else
    echo -e "${BLUE}=== Full Configuration Mode ===${NC}"
    echo
    
    echo -e "${YELLOW}Current UUID: $(grep "UUID = " app.py | head -1 | cut -d"'" -f2)${NC}"
    read -p "Enter new UUID (leave empty to auto-generate): " UUID_INPUT
    if [ -z "$UUID_INPUT" ]; then
        UUID_INPUT=$(generate_uuid)
        echo -e "${GREEN}Auto-generated UUID: $UUID_INPUT${NC}"
    fi
    sed -i "s/UUID = os.environ.get('UUID', '[^']*')/UUID = os.environ.get('UUID', '$UUID_INPUT')/" app.py
    echo -e "${GREEN}UUID set to: $UUID_INPUT${NC}"

    echo -e "${YELLOW}Current node name: $(grep "NAME = " app.py | head -1 | cut -d"'" -f4)${NC}"
    read -p "Enter node name (leave empty to keep current): " NAME_INPUT
    if [ -n "$NAME_INPUT" ]; then
        sed -i "s/NAME = os.environ.get('NAME', '[^']*')/NAME = os.environ.get('NAME', '$NAME_INPUT')/" app.py
        echo -e "${GREEN}Node name set to: $NAME_INPUT${NC}"
    fi

    echo -e "${YELLOW}Current service port: $(grep "PORT = int" app.py | grep -o "or [0-9]*" | cut -d" " -f2)${NC}"
    read -p "Enter service port (leave empty to keep current): " PORT_INPUT
    if [ -n "$PORT_INPUT" ]; then
        sed -i "s/PORT = int(os.environ.get('SERVER_PORT') or os.environ.get('PORT') or [0-9]*)/PORT = int(os.environ.get('SERVER_PORT') or os.environ.get('PORT') or $PORT_INPUT)/" app.py
        echo -e "${GREEN}Port set to: $PORT_INPUT${NC}"
    fi

    echo -e "${YELLOW}Current optimized IP: $(grep "CFIP = " app.py | cut -d"'" -f4)${NC}"
    read -p "Enter optimized IP/domain (leave empty to use default kick.com): " CFIP_INPUT
    if [ -z "$CFIP_INPUT" ]; then
        CFIP_INPUT="kick.com"
    fi
    sed -i "s/CFIP = os.environ.get('CFIP', '[^']*')/CFIP = os.environ.get('CFIP', '$CFIP_INPUT')/" app.py
    echo -e "${GREEN}Optimized IP set to: $CFIP_INPUT${NC}"

    echo -e "${YELLOW}Current optimized port: $(grep "CFPORT = " app.py | cut -d"'" -f4)${NC}"
    read -p "Enter optimized port (leave empty to keep current): " CFPORT_INPUT
    if [ -n "$CFPORT_INPUT" ]; then
        sed -i "s/CFPORT = int(os.environ.get('CFPORT', '[^']*'))/CFPORT = int(os.environ.get('CFPORT', '$CFPORT_INPUT'))/" app.py
        echo -e "${GREEN}Optimized port set to: $CFPORT_INPUT${NC}"
    fi

    echo -e "${YELLOW}Current Argo port: $(grep "ARGO_PORT = " app.py | cut -d"'" -f4)${NC}"
    read -p "Enter Argo port (leave empty to keep current): " ARGO_PORT_INPUT
    if [ -n "$ARGO_PORT_INPUT" ]; then
        sed -i "s/ARGO_PORT = int(os.environ.get('ARGO_PORT', '[^']*'))/ARGO_PORT = int(os.environ.get('ARGO_PORT', '$ARGO_PORT_INPUT'))/" app.py
        echo -e "${GREEN}Argo port set to: $ARGO_PORT_INPUT${NC}"
    fi

    echo -e "${YELLOW}Current subscription path: $(grep "SUB_PATH = " app.py | cut -d"'" -f4)${NC}"
    read -p "Enter subscription path (leave empty to keep current): " SUB_PATH_INPUT
    if [ -n "$SUB_PATH_INPUT" ]; then
        sed -i "s/SUB_PATH = os.environ.get('SUB_PATH', '[^']*')/SUB_PATH = os.environ.get('SUB_PATH', '$SUB_PATH_INPUT')/" app.py
        echo -e "${GREEN}Subscription path set to: $SUB_PATH_INPUT${NC}"
    fi

    echo
    echo -e "${YELLOW}Configure advanced options? (y/n)${NC}"
    read -p "> " ADVANCED_CONFIG

    if [ "$ADVANCED_CONFIG" = "y" ] || [ "$ADVANCED_CONFIG" = "Y" ]; then
        echo -e "${YELLOW}Current upload URL: $(grep "UPLOAD_URL = " app.py | cut -d"'" -f4)${NC}"
        read -p "Enter upload URL (leave empty to keep current): " UPLOAD_URL_INPUT
        if [ -n "$UPLOAD_URL_INPUT" ]; then
            sed -i "s|UPLOAD_URL = os.environ.get('UPLOAD_URL', '[^']*')|UPLOAD_URL = os.environ.get('UPLOAD_URL', '$UPLOAD_URL_INPUT')|" app.py
            echo -e "${GREEN}Upload URL set${NC}"
        fi

        echo -e "${YELLOW}Current project URL: $(grep "PROJECT_URL = " app.py | cut -d"'" -f4)${NC}"
        read -p "Enter project URL (leave empty to keep current): " PROJECT_URL_INPUT
        if [ -n "$PROJECT_URL_INPUT" ]; then
            sed -i "s|PROJECT_URL = os.environ.get('PROJECT_URL', '[^']*')|PROJECT_URL = os.environ.get('PROJECT_URL', '$PROJECT_URL_INPUT')|" app.py
            echo -e "${GREEN}Project URL set${NC}"
        fi

        echo -e "${YELLOW}Current auto-keepalive status: $(grep "AUTO_ACCESS = " app.py | grep -o "'[^']*'" | tail -1 | tr -d "'")${NC}"
        echo -e "${YELLOW}Enable auto-keepalive? (y/n)${NC}"
        read -p "> " AUTO_ACCESS_INPUT
        if [ "$AUTO_ACCESS_INPUT" = "y" ] || [ "$AUTO_ACCESS_INPUT" = "Y" ]; then
            sed -i "s/AUTO_ACCESS = os.environ.get('AUTO_ACCESS', '[^']*')/AUTO_ACCESS = os.environ.get('AUTO_ACCESS', 'true')/" app.py
            echo -e "${GREEN}Auto-keepalive enabled${NC}"
        elif [ "$AUTO_ACCESS_INPUT" = "n" ] || [ "$AUTO_ACCESS_INPUT" = "N" ]; then
            sed -i "s/AUTO_ACCESS = os.environ.get('AUTO_ACCESS', '[^']*')/AUTO_ACCESS = os.environ.get('AUTO_ACCESS', 'false')/" app.py
            echo -e "${GREEN}Auto-keepalive disabled${NC}"
        fi

        echo -e "${YELLOW}Current Nezha server: $(grep "NEZHA_SERVER = " app.py | cut -d"'" -f4)${NC}"
        read -p "Enter Nezha server address (leave empty to keep current): " NEZHA_SERVER_INPUT
        if [ -n "$NEZHA_SERVER_INPUT" ]; then
            sed -i "s|NEZHA_SERVER = os.environ.get('NEZHA_SERVER', '[^']*')|NEZHA_SERVER = os.environ.get('NEZHA_SERVER', '$NEZHA_SERVER_INPUT')|" app.py
            
            echo -e "${YELLOW}Current Nezha port: $(grep "NEZHA_PORT = " app.py | cut -d"'" -f4)${NC}"
            read -p "Enter Nezha port (leave empty for v1 version): " NEZHA_PORT_INPUT
            if [ -n "$NEZHA_PORT_INPUT" ]; then
                sed -i "s|NEZHA_PORT = os.environ.get('NEZHA_PORT', '[^']*')|NEZHA_PORT = os.environ.get('NEZHA_PORT', '$NEZHA_PORT_INPUT')|" app.py
            fi
            
            echo -e "${YELLOW}Current Nezha key: $(grep "NEZHA_KEY = " app.py | cut -d"'" -f4)${NC}"
            read -p "Enter Nezha key: " NEZHA_KEY_INPUT
            if [ -n "$NEZHA_KEY_INPUT" ]; then
                sed -i "s|NEZHA_KEY = os.environ.get('NEZHA_KEY', '[^']*')|NEZHA_KEY = os.environ.get('NEZHA_KEY', '$NEZHA_KEY_INPUT')|" app.py
            fi
            echo -e "${GREEN}Nezha configuration set${NC}"
        fi

        echo -e "${YELLOW}Current Argo domain: $(grep "ARGO_DOMAIN = " app.py | cut -d"'" -f4)${NC}"
        read -p "Enter Argo fixed tunnel domain (leave empty to keep current): " ARGO_DOMAIN_INPUT
        if [ -n "$ARGO_DOMAIN_INPUT" ]; then
            sed -i "s|ARGO_DOMAIN = os.environ.get('ARGO_DOMAIN', '[^']*')|ARGO_DOMAIN = os.environ.get('ARGO_DOMAIN', '$ARGO_DOMAIN_INPUT')|" app.py
            
            echo -e "${YELLOW}Current Argo auth: $(grep "ARGO_AUTH = " app.py | cut -d"'" -f4)${NC}"
            read -p "Enter Argo fixed tunnel auth: " ARGO_AUTH_INPUT
            if [ -n "$ARGO_AUTH_INPUT" ]; then
                sed -i "s|ARGO_AUTH = os.environ.get('ARGO_AUTH', '[^']*')|ARGO_AUTH = os.environ.get('ARGO_AUTH', '$ARGO_AUTH_INPUT')|" app.py
            fi
            echo -e "${GREEN}Argo fixed tunnel configuration set${NC}"
        fi

        echo -e "${YELLOW}Current Bot Token: $(grep "BOT_TOKEN = " app.py | cut -d"'" -f4)${NC}"
        read -p "Enter Telegram Bot Token (leave empty to keep current): " BOT_TOKEN_INPUT
        if [ -n "$BOT_TOKEN_INPUT" ]; then
            sed -i "s|BOT_TOKEN = os.environ.get('BOT_TOKEN', '[^']*')|BOT_TOKEN = os.environ.get('BOT_TOKEN', '$BOT_TOKEN_INPUT')|" app.py
            
            echo -e "${YELLOW}Current Chat ID: $(grep "CHAT_ID = " app.py | cut -d"'" -f4)${NC}"
            read -p "Enter Telegram Chat ID: " CHAT_ID_INPUT
            if [ -n "$CHAT_ID_INPUT" ]; then
                sed -i "s|CHAT_ID = os.environ.get('CHAT_ID', '[^']*')|CHAT_ID = os.environ.get('CHAT_ID', '$CHAT_ID_INPUT')|" app.py
            fi
            echo -e "${GREEN}Telegram configuration set${NC}"
        fi
    fi

    echo
    echo -e "${GREEN}Full configuration complete!${NC}"
fi

echo -e "${YELLOW}=== Current Configuration Summary ===${NC}"
echo -e "UUID: $(grep "UUID = " app.py | head -1 | cut -d"'" -f2)"
echo -e "Node Name: $(grep "NAME = " app.py | head -1 | cut -d"'" -f4)"
echo -e "Service Port: $(grep "PORT = int" app.py | grep -o "or [0-9]*" | cut -d" " -f2)"
echo -e "Optimized IP: $(grep "CFIP = " app.py | cut -d"'" -f4)"
echo -e "Optimized Port: $(grep "CFPORT = " app.py | cut -d"'" -f4)"
echo -e "Subscription Path: $(grep "SUB_PATH = " app.py | cut -d"'" -f4)"
echo -e "${YELLOW}========================${NC}"
echo

echo -e "${BLUE}Starting service...${NC}"
echo -e "${YELLOW}Current working directory: $(pwd)${NC}"
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
    exit 1
fi

SERVICE_PORT=$(grep "PORT = int" app.py | grep -o "or [0-9]*" | cut -d" " -f2)
CURRENT_UUID=$(grep "UUID = " app.py | head -1 | cut -d"'" -f2)
SUB_PATH_VALUE=$(grep "SUB_PATH = " app.py | cut -d"'" -f4)

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
    PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "Failed to get")
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
    DECODED_NODES=$(echo "$NODE_INFO" | base64 -d 2>/dev/null || echo "$NODE_INFO")
    echo -e "${GREEN}Raw Node Configuration:${NC}"
    echo "$DECODED_NODES"
    echo
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
