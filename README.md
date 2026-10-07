# ⚡ hey-cicd — DevSecOps Dashboard

## 📁 Project Structure

```
hey-cicd/
├── app/
│   ├── app.py              # Flask application
│   ├── templates/
│   │   └── index.html      # Dashboard UI
│   └── static/
│       ├── css/styles.css
│       └── js/main.js
├── tests/
│   └── test_app.py         # Unit tests
├── k8s/
│   ├── deployment.yaml     # Kubernetes Deployment
│   └── service.yaml        # Kubernetes Service
├── .github/
│   └── workflows/
│       └── devsecops.yml   # CI/CD Pipeline
├── Dockerfile
├── requirements.txt
├── requirements-dev.txt
└── README.md
```

---

## 🌐 API Endpoints

| Method | Route | Description |
|--------|-------|-------------|
| `GET` | `/` | Dashboard UI |
| `GET` | `/health` | Health check |
| `GET` | `/api/status` | App info, uptime, Python version |
| `GET` | `/api/greet/<name>` | Returns a greeting for the name |
| `POST` | `/api/add` | Adds two numbers |
| `POST` | `/api/calculate` | Calculator (add/subtract/multiply/divide/power/modulo) |
| `POST` | `/api/pipeline/run` | Simulates a CI/CD pipeline run |

---

## 🖥️ Method 1 — Run Manually (Python)

### Step 1 — Clone the repository

```bash
git clone https://github.com/m0y0nk/devsecops-demo.git
cd devsecops-demo
```

### Step 2 — Create a virtual environment

```bash
python3 -m venv .venv
source .venv/bin/activate        # Mac/Linux
# .venv\Scripts\activate         # Windows
```

### Step 3 — Install dependencies

```bash
pip install -r requirements.txt
```

### Step 4 — Run the app

```bash
python3 app/app.py
```

### Step 5 — Open in browser

```
http://localhost:5001
```

### Step 6 — Run the tests

```bash
pip install -r requirements-dev.txt
python3 -m pytest --cov=app --cov-report=term-missing
```

**Expected output:**
```
tests/test_app.py::test_home                      PASSED
tests/test_app.py::test_health                    PASSED
tests/test_app.py::test_greet                     PASSED
tests/test_app.py::test_add_numbers               PASSED
tests/test_app.py::test_add_numbers_missing_fields PASSED
tests/test_app.py::test_calculator_multiply       PASSED
tests/test_app.py::test_calculator_divide_by_zero PASSED
tests/test_app.py::test_status                    PASSED
8 passed in 0.Xs
```

### Test the API manually

```bash
# Health check
curl http://localhost:5001/health

# Greet someone
curl http://localhost:5001/api/greet/Nensi

# Add two numbers
curl -X POST http://localhost:5001/api/add \
  -H "Content-Type: application/json" \
  -d '{"number1": 10, "number2": 20}'

# Calculator
curl -X POST http://localhost:5001/api/calculate \
  -H "Content-Type: application/json" \
  -d '{"a": 6, "b": 3, "operation": "multiply"}'
```

---

## 🐳 Method 2 — Run with Docker

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running

### Step 1 — Build the Docker image

```bash
docker build -t hey-cicd:latest .
```

### Step 2 — Run the container

```bash
docker run -p 5001:5001 hey-cicd:latest
```

### Step 3 — Open in browser

```
http://localhost:5001
```

### Useful Docker commands

```bash
# See running containers
docker ps

# Stop the container
docker stop <container-id>

# Remove the image
docker rmi hey-cicd:latest

# Run in background (detached mode)
docker run -d -p 5001:5001 hey-cicd:latest
```

---

## ⚙️ Method 3 — CI/CD Pipeline (GitHub Actions)

The pipeline runs on pushes and pull requests targeting `main`. Tests, CodeQL,
dependency audit, and Gitleaks run before the image is built and scanned.
Publishing and deployment run only on pushes to `main`.

### Pipeline Stages

```
Push or pull request to main
      │
      ├─ Tests ─┐
      ├─ CodeQL ├─ Run in parallel; all must pass
      ├─ pip-audit
      └─ Gitleaks
             │
             ▼
      Build Docker image
             │
             ▼
      Trivy vulnerability gate
             │
             ├─ Pull request: finish without publish
             │
             └─ Push to main:
                    Push scanned image to Docker Hub
                              │
                              ▼
                    Deploy to temporary Kind cluster
```

The runtime image uses the Python 3.12 Alpine image, installs only
the application requirements, and runs as a non-root numeric user. The workflow
uses `docker build --pull` and scans that same commit-tagged image before any
registry push. Keep the HIGH/CRITICAL Trivy threshold enabled; if it fails,
review the findings and update affected components before publishing.

### How to trigger the pipeline

```bash
# Make a change, commit, and push
git add .
git commit -m "your message"
git push origin main
```

Then go to your GitHub repo → **Actions** tab to watch it run.

### Required GitHub Secrets

Go to **GitHub repo → Settings → Secrets and variables → Actions** and add:

| Secret Name | Value |
|-------------|-------|
| `DOCKERHUB_TOKEN` | Docker Hub access token used to publish images |

`GITHUB_TOKEN` is automatically provided by GitHub for CodeQL and Gitleaks.
The deployment job creates a temporary Kind cluster in GitHub Actions; it does
not deploy to a cluster on your computer.

### View your Docker image after push

After a successful push to `main`, your image is available at:
```
m0y0nk/devsecops-homework:latest
```

Open the `devsecops-homework` repository in Docker Hub to see it. The workflow
pushes both `latest` and the commit-SHA tag. Pull requests run checks and scan,
but do not publish or deploy. The Docker Hub repository must be public for the
temporary Kubernetes cluster to pull the image.

---

## ☸️ Method 4 — Deploy to Kubernetes manually

> Do this if you want to deploy without the pipeline, directly from your terminal.

### Prerequisites
- A running Kubernetes cluster (minikube, k3s, or cloud)
- `kubectl` installed and connected to your cluster

### Step 1 — Apply the manifests

```bash
sed 's|__IMAGE_TAG__|latest|g' k8s/deployment.yaml > /tmp/devsecops-homework-deployment.yaml
kubectl apply -f /tmp/devsecops-homework-deployment.yaml
kubectl apply -f k8s/service.yaml
```

This assumes the Docker Hub repository is public and the `latest` image has
already been published. The pipeline substitutes the commit SHA automatically.

### Step 2 — Check the pods are running

```bash
kubectl get pods
kubectl get service session17-python
```

### Step 3 — Access the app

```bash
# If using minikube
minikube service session17-python

# Or access via NodePort
http://<your-node-ip>:30001
```

### Useful kubectl commands

```bash
# See all running pods
kubectl get pods

# See logs from a pod
kubectl logs <pod-name>

# Delete the deployment
kubectl delete -f k8s/deployment.yaml
kubectl delete -f k8s/service.yaml
```

---

## 🧪 DevSecOps Concepts Covered

| Concept | Tool Used | Where |
|---------|-----------|-------|
| **Unit Testing** | pytest + pytest-cov | `tests/test_app.py` |
| **SAST** (Static Application Security Testing) | GitHub CodeQL | Security checks job |
| **SCA** (Software Composition Analysis) | pip-audit | Security checks job |
| **Secret Scanning** | Gitleaks | Security checks job |
| **Containerisation** | Docker | `Dockerfile` |
| **Container Image Scanning** | Trivy | Build/scan/push job |
| **Container Registry** | Docker Hub | Build/scan/push job |
| **Orchestration** | Kubernetes | `k8s/` folder |
| **CI/CD Automation** | GitHub Actions | `.github/workflows/devsecops.yml` |

---

## 👩‍💻 Built With

- **Python 3.12** + **Flask 3.x**
- **Docker**
- **Kubernetes**
- **GitHub Actions**