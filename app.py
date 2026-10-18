from flask import Flask, render_template, jsonify
import time

app = Flask(__name__)
START_TIME = time.time()

# Version indicator - change this to demonstrate Jenkins Webhook CI/CD in action!
APP_VERSION = "v1.0.0"
AUTHOR = "Shivam Shirsat"
COURSE = "Cloud Computing & DevOps"

@app.route("/")
def home():
    return render_template(
        "index.html",
        author=AUTHOR,
        course=COURSE,
        app_version=APP_VERSION
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
    return jsonify({
        "status": "UP",
        "uptime_seconds": uptime_seconds,
        "environment": "AWS EC2 (t2.micro)",
        "orchestration": "Minikube / Kubernetes",
        "container": "Docker"
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
