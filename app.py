from flask import Flask, render_template, jsonify
import time
import socket
import os
import platform

app = Flask(__name__)
START_TIME = time.time()

APP_VERSION = "v1.0.0"
AUTHOR = "Shivam Shirsat"
COURSE = "Cloud Computing & DevOps"

@app.route("/")
def home():
    pod_name = socket.gethostname()
    try:
        pod_ip = socket.gethostbyname(pod_name)
    except Exception:
        pod_ip = "127.0.0.1"

    return render_template(
        "index.html",
        author=AUTHOR,
        course=COURSE,
        app_version=APP_VERSION,
        pod_name=pod_name,
        pod_ip=pod_ip
    )

@app.route("/student")
def student():
    return jsonify({
        "name": AUTHOR,
        "course": COURSE,
        "role": "Student",
        "assignment": "Assignment 5 / Mini Project - CI/CD & Kubernetes",
        "version": APP_VERSION
    })

@app.route("/health")
def health():
    uptime_seconds = round(time.time() - START_TIME, 1)
    pod_name = socket.gethostname()
    try:
        pod_ip = socket.gethostbyname(pod_name)
    except Exception:
        pod_ip = "127.0.0.1"

    return jsonify({
        "status": "UP",
        "uptime_seconds": uptime_seconds,
        "kubernetes_pod": pod_name,
        "kubernetes_pod_ip": pod_ip,
        "orchestration": "Minikube / Kubernetes",
        "container_runtime": "Docker (python:3.11-slim)",
        "cloud_provider": "AWS EC2",
        "service_port": 30000,
        "os_details": platform.platform()
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
