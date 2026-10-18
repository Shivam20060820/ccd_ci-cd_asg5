# Cloud Computing & DevOps (CCD) - Mini Project / Assignment 5

Automated demonstration of **AWS EC2**, **Docker Containerization**, **Kubernetes (Minikube)**, **Jenkins CI/CD**, and **GitHub Webhook** with a barebone lightweight microservice optimized for AWS EC2 `t2.micro`.

---

## ⚡ Super Quick Start (One-Command Deployment)

On your AWS EC2 instance (Ubuntu), simply run:

```bash
git clone https://github.com/Shivam20060820/ccd_ci-cd_asg5.git
cd ccd_ci-cd_asg5
chmod +x deploy.sh
./deploy.sh
```

### What `deploy.sh` does automatically:
1. **Creates 2GB Swap Memory**: Guarantees your `t2.micro` (1GB RAM) will **never freeze or crash**.
2. **Auto-installs missing tools**: Checks and installs Docker, Kubectl, and Minikube if not already present.
3. **Starts Minikube**: Configured safely with memory constraints (`1400MB`, `1 CPU`).
4. **Builds the Docker Container**: Packages `cloud-app:latest` using the lightweight `python:3.11-slim` image.
5. **Loads Image into Kubernetes**: Transfers the image directly into Minikube.
6. **Deploys Pods & NodePort**: Applies `k8s.yaml` and verifies rollout status.
7. **Prints your live URL**: Detects your EC2 Public IP and displays `http://<EC2-PUBLIC-IP>:30000`.

---

## 🏗️ Architecture & Pipeline Flow

```
[Developer Push] 
       │
       ▼
[GitHub Repository] ──(GitHub Webhook)──▶ [AWS EC2 (t2.micro)]
                                                │
                                                ▼
                                         [Jenkins CI/CD]
                                                │
                                                ├─▶ 1. Pulls latest commit
                                                ├─▶ 2. Builds Docker image (`python:3.11-slim`)
                                                ├─▶ 3. Loads image into Minikube
                                                └─▶ 4. Applies `k8s.yaml` & rollout restart
                                                        │
                                                        ▼
                                         [Kubernetes / Minikube]
                                                │
                                                ▼
                                       [cloud-app Pod & NodePort :30000]
```

---

## 🛠️ Jenkins CI/CD & Webhook Setup

If you want Jenkins to automatically build and deploy every time you push code to GitHub:

### 1. Install Jenkins on EC2
Run the automated Jenkins setup included in the script:
```bash
./deploy.sh --install-jenkins
```
This prints your Jenkins URL (`http://<EC2-IP>:8080`) and the Initial Admin Password.

### 2. Configure GitHub Webhook
1. Go to your GitHub Repository -> **Settings** -> **Webhooks** -> **Add webhook**.
2. **Payload URL**: `http://<EC2-PUBLIC-IP>:8080/github-webhook/`
3. **Content type**: `application/json`
4. **Which events**: "Just the push event"
5. Click **Add webhook**.

### 3. Create a Pipeline Job in Jenkins
1. Open `http://<EC2-IP>:8080` in your browser.
2. Click **New Item** -> Name it `cloud-app-pipeline` -> Select **Pipeline** -> Click **OK**.
3. Under **Build Triggers**, check: **GitHub hook trigger for GITScm polling**.
4. Under **Pipeline** definition:
   - Select: **Pipeline script from SCM**.
   - SCM: **Git**.
   - Repository URL: `https://github.com/Shivam20060820/ccd_ci-cd_asg5.git`.
   - Branch Specifier: `*/main` (or `*/lt`).
   - Script Path: `Jenkinsfile`.
5. Click **Save**.

Now, whenever you push code, Jenkins automatically triggers, builds, and deploys!

---

## 🔒 AWS EC2 Security Group Inbound Rules

Make sure these ports are open in your EC2 Security Group:
| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 22 | TCP | Anywhere / My IP | SSH access |
| 8080 | TCP | Anywhere (0.0.0.0/0) | Jenkins & GitHub Webhook |
| 30000 | TCP | Anywhere (0.0.0.0/0) | Live Webpage (Kubernetes NodePort) |

---

## 🔍 Live API Endpoints

- `GET /`: Modern responsive dashboard with live server status, author details, and interactive testing buttons.
- `GET /student`: Returns JSON metadata for the student and course.
- `GET /health`: Returns JSON container health status, uptime, and orchestration environment for Kubernetes probes.
