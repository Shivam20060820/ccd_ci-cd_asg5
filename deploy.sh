#!/usr/bin/env bash

# ==============================================================================
# Cloud Computing & DevOps (CCD) - All-In-One Automated Deployment Script
# Designed for AWS EC2 (t2.micro) with Docker, Minikube (Kubernetes), & Jenkins
# ==============================================================================

set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

APP_NAME="cloud-app"
IMAGE_TAG="latest"
PORT="30000"

print_header() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${CYAN}    CCD CI/CD & Kubernetes All-In-One Automation Script          ${NC}"
    echo -e "${CYAN}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 1. SETUP SWAP MEMORY (CRITICAL FOR t2.micro 1GB RAM)
# ------------------------------------------------------------------------------
setup_swap() {
    echo -e "\n${BLUE}[1/5] Checking Swap Memory for t2.micro...${NC}"
    SWAP_EXIST=$(free -m | awk '/Swap:/ {print $2}')
    if [ "$SWAP_EXIST" -eq 0 ]; then
        echo -e "${YELLOW}>> No swap detected. Creating 2GB swapfile to prevent t2.micro crash...${NC}"
        sudo fallocate -l 2G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
        echo -e "${GREEN}>> 2GB swap successfully created and enabled!${NC}"
    else
        echo -e "${GREEN}>> Swap is already configured (${SWAP_EXIST} MB). Skipping.${NC}"
    fi
}

# ------------------------------------------------------------------------------
# 2. CHECK / INSTALL PREREQUISITES (Docker, Kubectl, Minikube)
# ------------------------------------------------------------------------------
install_prerequisites() {
    echo -e "\n${BLUE}[2/5] Checking and Installing Docker, Kubectl, & Minikube...${NC}"
    
    # 2.1 Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}>> Docker not found. Installing Docker...${NC}"
        sudo apt-get update -y
        sudo apt-get install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker "$USER"
        echo -e "${GREEN}>> Docker installed successfully.${NC}"
    else
        echo -e "${GREEN}>> Docker is already installed.${NC}"
    fi

    # Ensure docker daemon is active
    sudo systemctl start docker || true

    # 2.2 Kubectl
    if ! command -v kubectl &> /dev/null; then
        echo -e "${YELLOW}>> Kubectl not found. Installing Kubectl...${NC}"
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm -f kubectl
        echo -e "${GREEN}>> Kubectl installed successfully.${NC}"
    else
        echo -e "${GREEN}>> Kubectl is already installed.${NC}"
    fi

    # 2.3 Minikube
    if ! command -v minikube &> /dev/null; then
        echo -e "${YELLOW}>> Minikube not found. Installing Minikube...${NC}"
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        sudo install minikube-linux-amd64 /usr/local/bin/minikube
        rm -f minikube-linux-amd64
        echo -e "${GREEN}>> Minikube installed successfully.${NC}"
    else
        echo -e "${GREEN}>> Minikube is already installed.${NC}"
    fi
}

# ------------------------------------------------------------------------------
# 3. START MINIKUBE (Optimized for t2.micro)
# ------------------------------------------------------------------------------
start_minikube() {
    echo -e "\n${BLUE}[3/5] Starting / Checking Minikube Cluster...${NC}"
    
    # Check if minikube is already running
    if minikube status | grep -q "Running"; then
        echo -e "${GREEN}>> Minikube is already running.${NC}"
    else
        echo -e "${YELLOW}>> Starting Minikube (configured with 1400MB memory & 1 CPU)...${NC}"
        # If user is in docker group or use sudo if needed
        minikube start --driver=docker --memory=1400m --cpus=1 || sudo -E minikube start --driver=docker --memory=1400m --cpus=1 --force
        echo -e "${GREEN}>> Minikube cluster is up and ready!${NC}"
    fi
}

# ------------------------------------------------------------------------------
# 4. BUILD CONTAINER & LOAD INTO MINIKUBE
# ------------------------------------------------------------------------------
build_and_load() {
    echo -e "\n${BLUE}[4/5] Building Docker Image & Loading into Kubernetes...${NC}"
    
    echo -e "${CYAN}>> Running: docker build -t ${APP_NAME}:${IMAGE_TAG} .${NC}"
    docker build -t ${APP_NAME}:${IMAGE_TAG} . || sudo docker build -t ${APP_NAME}:${IMAGE_TAG} .
    
    echo -e "${CYAN}>> Loading image into Minikube cluster registry...${NC}"
    minikube image load ${APP_NAME}:${IMAGE_TAG} || sudo minikube image load ${APP_NAME}:${IMAGE_TAG}
    echo -e "${GREEN}>> Image ${APP_NAME}:${IMAGE_TAG} loaded into Minikube.${NC}"
}

# ------------------------------------------------------------------------------
# 5. DEPLOY TO KUBERNETES & VERIFY
# ------------------------------------------------------------------------------
deploy_k8s() {
    echo -e "\n${BLUE}[5/5] Applying Kubernetes Manifests (k8s.yaml)...${NC}"
    
    kubectl apply -f k8s.yaml || sudo kubectl apply -f k8s.yaml
    
    echo -e "${CYAN}>> Rolling out update to deployment/${APP_NAME}...${NC}"
    kubectl rollout restart deployment/${APP_NAME} || sudo kubectl rollout restart deployment/${APP_NAME}
    
    echo -e "${CYAN}>> Waiting for Pod to be ready (timeout: 90s)...${NC}"
    kubectl rollout status deployment/${APP_NAME} --timeout=90s || sudo kubectl rollout status deployment/${APP_NAME} --timeout=90s
    
    echo -e "\n${GREEN}=================================================================${NC}"
    echo -e "${GREEN}               🎉 DEPLOYMENT SUCCESSFUL!                         ${NC}"
    echo -e "${GREEN}=================================================================${NC}"
    
    # Show active pods & services
    echo -e "\n${CYAN}Active Kubernetes Pods:${NC}"
    kubectl get pods -l app=${APP_NAME} || sudo kubectl get pods -l app=${APP_NAME}
    
    echo -e "\n${CYAN}Kubernetes Service Details:${NC}"
    kubectl get svc cloud-app-service || sudo kubectl get svc cloud-app-service
    
    # Determine Public IP
    PUBLIC_IP=$(curl -s -m 5 https://api.ipify.org || curl -s -m 5 http://checkip.amazonaws.com || echo "<YOUR-EC2-PUBLIC-IP>")
    
    echo -e "\n${YELLOW}-----------------------------------------------------------------${NC}"
    echo -e "${YELLOW} Access your live web application at:${NC}"
    echo -e "${GREEN}   👉  http://${PUBLIC_IP}:${PORT}${NC}"
    echo -e "${YELLOW} Test API Endpoints:${NC}"
    echo -e "   👤 Student Info: http://${PUBLIC_IP}:${PORT}/student"
    echo -e "   💚 Health Probe: http://${PUBLIC_IP}:${PORT}/health"
    echo -e "${YELLOW}-----------------------------------------------------------------${NC}"
    echo -e "${CYAN}(Note: Ensure AWS Security Group allows inbound TCP traffic on port ${PORT})${NC}\n"
}

# ------------------------------------------------------------------------------
# OPTIONAL: INSTALL & CONFIGURE JENKINS
# ------------------------------------------------------------------------------
install_jenkins() {
    echo -e "\n${BLUE}[Optional] Installing Jenkins on AWS EC2...${NC}"
    sudo apt-get update -y
    sudo apt-get install -y fontconfig openjdk-17-jre
    
    sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    
    sudo apt-get update -y
    sudo apt-get install -y jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    
    # Grant permissions to jenkins user
    sudo usermod -aG docker jenkins || true
    if [ -d "$HOME/.kube" ]; then
        sudo mkdir -p /var/lib/jenkins/.kube
        sudo cp -r "$HOME/.kube" /var/lib/jenkins/
        sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
    fi
    sudo systemctl restart jenkins
    
    PUBLIC_IP=$(curl -s -m 5 https://api.ipify.org || echo "<YOUR-EC2-PUBLIC-IP>")
    INITIAL_PWD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "Run: sudo cat /var/lib/jenkins/secrets/initialAdminPassword")
    
    echo -e "${GREEN}>> Jenkins installed and running!${NC}"
    echo -e "${YELLOW}Jenkins URL: http://${PUBLIC_IP}:8080${NC}"
    echo -e "${YELLOW}Initial Admin Password: ${INITIAL_PWD}${NC}"
}

# ------------------------------------------------------------------------------
# SCRIPT CONTROLLER / ARGUMENT PARSER
# ------------------------------------------------------------------------------
print_header

case "$1" in
    --setup-only)
        setup_swap
        install_prerequisites
        ;;
    --start-cluster)
        start_minikube
        ;;
    --deploy-only)
        build_and_load
        deploy_k8s
        ;;
    --install-jenkins)
        install_jenkins
        ;;
    *)
        # Default: Full end-to-end execution
        setup_swap
        install_prerequisites
        start_minikube
        build_and_load
        deploy_k8s
        ;;
esac
