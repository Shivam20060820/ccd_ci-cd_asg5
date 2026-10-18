# 🛠️ Complete Project Command Reference Cheat Sheet
### Cloud Computing & DevOps (CCD) Mini Project: AWS EC2, Docker, Kubernetes (Minikube), Jenkins & GitHub Webhook

---

## ⚡ 1. Quick Start (All-in-One Command)
If setting up on an EC2 instance from scratch:
```bash
sudo chmod 666 /var/run/docker.sock 2>/dev/null; [ -d "ccd_ci-cd_asg5" ] || git clone https://github.com/Shivam20060820/ccd_ci-cd_asg5.git; cd ccd_ci-cd_asg5 && git checkout lt && git pull origin lt && chmod +x deploy.sh && ./deploy.sh
```

---

## ☁️ 2. AWS EC2 & System Setup Commands

### Create 2GB Swap Memory (Prevents RAM lockup)
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
free -h
```

### Find EC2 Public IP Address
```bash
curl -s https://api.ipify.org
# or
curl -s http://checkip.amazonaws.com
```

### Check Listening Ports
```bash
sudo ss -tulpn | grep -E '30000|8080|5000'
```

---

## 🐳 3. Docker Commands (Containerization)

### Fix Docker Permission (Run without sudo)
```bash
sudo chmod 666 /var/run/docker.sock
sudo usermod -aG docker $USER
```

### Build Docker Image
```bash
docker build -t cloud-app:latest .
```

### List Docker Images
```bash
docker images | grep cloud-app
```

### Run Container Standalone (Testing without Kubernetes)
```bash
docker run -d -p 5000:5000 --name test-app cloud-app:latest
```

### View Running Containers
```bash
docker ps
```

### View Docker Container Logs
```bash
docker logs test-app
```

### Stop and Remove Container
```bash
docker stop test-app && docker rm test-app
```

---

## ☸️ 4. Kubernetes & Minikube Commands (Orchestration)

### Start Minikube
```bash
# Standard start (t3.medium / 2 CPUs):
minikube start --driver=docker --memory=2048m --cpus=2

# Fallback start for single-core / low RAM (t2.micro):
sudo -E minikube start --driver=none --extra-config=kubeadm.ignore-preflight-errors=NumCPU,Mem --force
```

### Check Cluster & Node Status
```bash
minikube status
kubectl get nodes
```

### Load Docker Image into Minikube
```bash
minikube image load cloud-app:latest
```

### Deploy Application to Kubernetes
```bash
kubectl apply -f k8s.yaml
```

### Check Running Pods (Shows Pod Name and Internal IP)
```bash
kubectl get pods -o wide
```

### Check Deployment & Service
```bash
kubectl get deployments
kubectl get svc cloud-app-service
```

### Restart Deployment (Trigger Rolling Update)
```bash
kubectl rollout restart deployment/cloud-app
kubectl rollout status deployment/cloud-app
```

### Bridge NodePort to Public IP (Port-Forward in Background)
```bash
pkill -f "port-forward.*30000" 2>/dev/null || true
nohup kubectl port-forward --address 0.0.0.0 svc/cloud-app-service 30000:5000 >/dev/null 2>&1 &
```

### View Live Pod Logs
```bash
kubectl logs -l app=cloud-app --tail=30 -f
```

### Access Shell Inside Kubernetes Pod
```bash
kubectl exec -it $(kubectl get pods -l app=cloud-app -o jsonpath='{.items[0].metadata.name}') -- /bin/bash
```

### Clean / Delete Deployment
```bash
kubectl delete -f k8s.yaml
```

---

## 🔄 5. Jenkins Commands (CI/CD Pipeline)

### Install Jenkins with Java 21
```bash
# 1. Purge old Java and install Java 21
sudo apt-get purge -y 'openjdk-17*'
sudo apt-get update -y
sudo apt-get install -y fontconfig openjdk-21-jdk

# 2. Add Jenkins official repository keyring
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# 3. Install and start Jenkins
sudo apt-get update -y
sudo apt-get install -y jenkins
sudo systemctl daemon-reload
sudo systemctl restart jenkins
sudo systemctl enable jenkins
```

### Read Initial Admin Password
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Grant Jenkins Full Sudo & Docker Permissions (Crucial for CI/CD)
```bash
echo "jenkins ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/jenkins
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Check Jenkins Service Status
```bash
sudo systemctl status jenkins
```

### Reset Jenkins if Rate-Limited by Systemd
```bash
sudo systemctl reset-failed jenkins
sudo systemctl restart jenkins
```

---

## 🌐 6. Git & Webhook Commands

### Test Automated CI/CD Webhook Trigger (Empty Commit)
```bash
git commit --allow-empty -m "Trigger automated Jenkins webhook"
git push origin lt
```

### Trigger CI/CD with Real Code Change (Version Update)
```bash
# 1. Edit APP_VERSION in app.py to "v2.0.0"
# 2. Push commit:
git add app.py
git commit -m "Bump version to v2.0.0"
git push origin lt
```

### Pull Latest Changes on EC2
```bash
git checkout lt
git pull origin lt
```

---

## 🔍 7. Verification & Live API Testing Commands

### Test Live Web App (from EC2 terminal)
```bash
curl -I http://localhost:30000
```

### Test `/student` Endpoint
```bash
curl -s http://localhost:30000/student | jq .
```

### Test `/health` Endpoint (Kubernetes Probe)
```bash
curl -s http://localhost:30000/health | jq .
```

---

## 🚨 8. Quick Fixes / Troubleshooting

| Problem | Instant Command Fix |
|---|---|
| **Port 30000 not reachable in browser** | `nohup kubectl port-forward --address 0.0.0.0 svc/cloud-app-service 30000:5000 >/dev/null 2>&1 &` *(Also verify AWS Security Group Port 30000 is open)* |
| **Docker permission denied** | `sudo chmod 666 /var/run/docker.sock` |
| **Minikube profile not found in Jenkins** | `echo "jenkins ALL=(ALL) NOPASSWD: ALL" \| sudo tee /etc/sudoers.d/jenkins` |
| **Jenkins initialAdminPassword missing** | `sudo systemctl reset-failed jenkins && sudo systemctl restart jenkins && sleep 20 && sudo cat /var/lib/jenkins/secrets/initialAdminPassword` |
| **Kill stuck port-forward** | `pkill -f "port-forward.*30000"` |
