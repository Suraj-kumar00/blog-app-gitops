# Kubernetes, ArgoCD, and Tekton Deployment Guide

This document provides a comprehensive guide to deploying a Ruby on Rails application with PostgreSQL using Kubernetes, ArgoCD for GitOps, and Tekton for CI/CD pipelines.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Kubernetes Deployment](#kubernetes-deployment)
- [ArgoCD Setup](#argocd-setup)
- [Tekton Pipelines](#tekton-pipelines)
- [End-to-End Workflow](#end-to-end-workflow)
- [Concepts Explained](#concepts-explained)

## Prerequisites

Before getting started, ensure you have the following tools installed:

- Docker
- Kubernetes cluster (Minikube or K3d)
- kubectl
- Git
- GitHub account (for private repository)
- Docker Hub account (for storing container images)

## Kubernetes Deployment

### Step 1: Set Up a Local Kubernetes Cluster

Using Minikube:

```bash
# Start Minikube with adequate resources
minikube start --cpus=4 --memory=8g --disk-size=20g

# Enable the ingress addon
minikube addons enable ingress
```

Using K3d:

```bash
# Create a K3d cluster with port mapping
k3d cluster create blog-cluster -p "80:80@loadbalancer" -p "443:443@loadbalancer" --agents 2
```

### Step 2: Create a Namespace

```bash
# Create the namespace for our application
kubectl apply -f kubernetes/namespace.yaml
```

### Step 3: Deploy PostgreSQL StatefulSet

PostgreSQL is deployed as a StatefulSet to ensure data persistence:

```bash
# Apply the PostgreSQL StatefulSet configuration
kubectl apply -f kubernetes/postgres-statefulset.yaml
```

The StatefulSet ensures:

- Stable network identities for PostgreSQL pods
- Persistent storage with PersistentVolumeClaims
- Ordered deployment and scaling

### Step 4: Deploy Redis

Redis is used for caching and background processing:

```bash
# Apply the Redis deployment
kubectl apply -f kubernetes/redis-deployment.yaml
```

### Step 5: Deploy the Rails Application

```bash
# Apply the Rails deployment configuration
kubectl apply -f kubernetes/rails-deployment.yaml
```

The deployment includes:

- ConfigMaps for environment variables
- Secrets for sensitive data
- Health checks for reliability
- Rolling update strategy for zero-downtime deployments

### Step 6: Configure Ingress

```bash
# Apply the Ingress configuration
kubectl apply -f kubernetes/ingress.yaml
```

The Ingress allows external access to your application through a domain name.

### Step 7: Verify Deployment

```bash
# Check all resources in the namespace
kubectl get all -n blog-app

# Verify pods are running
kubectl get pods -n blog-app

# Check services
kubectl get svc -n blog-app

# Test the Ingress
kubectl get ingress -n blog-app
```

## ArgoCD Setup

ArgoCD implements GitOps practices by continuously synchronizing your Kubernetes cluster with a Git repository.

### Step 1: Install ArgoCD

```bash
# Create the ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD pods to be ready
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
```

### Step 2: Access the ArgoCD Dashboard

```bash
# Port-forward the ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode && echo
```

Visit http://localhost:8080 and login with username `admin` and the password from the command above.

### Step 3: Configure GitHub Repository

1. Create a private GitHub repository for GitOps (e.g., `blog-app-gitops`)
2. Push your Kubernetes manifests to this repository:
   ```bash
   git clone https://github.com/Suraj-kumar00/blog-app-gitops.git
   mkdir -p blog-app-gitops/kubernetes
   cp -r kubernetes/* blog-app-gitops/kubernetes/
   git add .
   git commit -m "Initial commit of Kubernetes manifests"
   git push
   ```

### Step 4: Configure ArgoCD Repository and Application

Apply the ArgoCD configurations:

```bash
# Apply the repository secret
kubectl apply -f argocd/repository.yaml

# Apply the ArgoCD ConfigMaps
kubectl apply -f argocd/argocd-cm.yaml
kubectl apply -f argocd/argocd-rbac-cm.yaml

# Apply the application configuration
kubectl apply -f argocd/application.yaml
```

### Step 5: Verify ArgoCD Sync

In the ArgoCD UI:

1. Navigate to the "Applications" section
2. Click on the "blog-app" application
3. Check the sync status and resource health
4. If necessary, click "Sync" to manually trigger synchronization

## Tekton Pipelines

Tekton is a Kubernetes-native CI/CD solution that builds and deploys your application.

### Step 1: Install Tekton Pipelines and Dashboard

```bash
# Install Tekton Pipelines
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

# Install Tekton Dashboard
kubectl apply -f https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml

# Wait for Tekton components to be ready
kubectl wait --for=condition=Ready pods --all -n tekton-pipelines --timeout=300s
```

### Step 2: Install Tekton Tasks

```bash
# Install the git-clone task
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.9/git-clone.yaml

# Install the kaniko task for building container images
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/kaniko/0.6/kaniko.yaml
```

### Step 3: Configure Docker Hub Credentials

```bash
# Apply the Docker Hub credentials
kubectl apply -f tekton/docker-credentials.yaml
```

### Step 4: Create Pipeline

```bash
# Apply the pipeline definition
kubectl apply -f tekton/pipeline.yaml
```

### Step 5: Access the Tekton Dashboard

```bash
# Port-forward the Tekton dashboard
kubectl port-forward svc/tekton-dashboard -n tekton-pipelines 9097:9097
```

Visit http://localhost:9097 to access the Tekton Dashboard.

### Step 6: Run the Pipeline

Using the Tekton Dashboard:

1. Navigate to "PipelineRuns"
2. Click "Create PipelineRun"
3. Select the "blog-app-pipeline"
4. Configure parameters as needed
5. Click "Create"

Or from the command line:

```bash
# Start a pipeline run
kubectl create -f tekton/pipelinerun.yaml
```

## End-to-End Workflow

The complete CI/CD workflow:

1. Developer pushes code to the application repository
2. Tekton pipeline is triggered (manually or via webhooks)
3. Tekton:
   - Clones the application repository
   - Builds a container image using Kaniko
   - Pushes the image to Docker Hub
4. Developer updates the image tag in the GitOps repository
5. ArgoCD detects the change and synchronizes the Kubernetes cluster
6. Kubernetes rolls out the new version of the application

## Concepts Explained

### Kubernetes

Kubernetes is a container orchestration platform that automates the deployment, scaling, and management of containerized applications.

Key components used in our setup:

- **Namespace**: Provides isolation for resources
- **StatefulSet**: Used for PostgreSQL to ensure stable network identities and persistent storage
- **Deployment**: Manages the Rails application replicas
- **Service**: Provides network access to pods
- **ConfigMap**: Stores non-sensitive configuration
- **Secret**: Stores sensitive data
- **Ingress**: Routes external traffic to services

Benefits:

- **Scalability**: Easily scale components independently
- **Reliability**: Self-healing capabilities
- **Portability**: Works across various infrastructure providers

### StatefulSet vs Deployment

- **StatefulSet**: Used for PostgreSQL because it provides:

  - Stable, unique network identifiers
  - Stable, persistent storage
  - Ordered, graceful deployment and scaling
  - Ordered, automated rolling updates

- **Deployment**: Used for the Rails application because it provides:
  - Declarative updates
  - Rolling updates and rollbacks
  - Replica scaling
  - Suitable for stateless applications

### GitOps with ArgoCD

GitOps is an operational framework that uses Git as the single source of truth for declarative infrastructure and applications.

ArgoCD implements GitOps by:

1. Monitoring Git repositories for changes
2. Comparing the desired state (Git) with the actual state (Kubernetes)
3. Automatically syncing the cluster to match the Git repository

Benefits:

- **Versioned**: All changes are tracked in Git
- **Auditable**: Complete history of changes
- **Reversible**: Easy rollbacks to previous states
- **Self-documenting**: Configuration as code

### CI/CD with Tekton

Tekton is a Kubernetes-native framework for creating CI/CD systems.

Key components:

- **Tasks**: Individual steps in a pipeline
- **Pipeline**: A series of tasks
- **PipelineRun**: An execution of a pipeline
- **Workspaces**: Shared storage between tasks

Benefits:

- **Cloud Native**: Runs directly on Kubernetes
- **Scalable**: Leverages Kubernetes for scaling
- **Flexible**: Build custom pipelines with reusable components
- **Extensible**: Use or create tasks from the Tekton Catalog

### Best Practices

1. **Secrets Management**:

   - Never commit secrets to Git
   - Use Kubernetes Secrets or external secret management tools

2. **Resource Management**:

   - Set resource requests and limits for all containers
   - Monitor resource usage

3. **High Availability**:

   - Run multiple replicas of the Rails application
   - Use readiness and liveness probes

4. **Security**:
   - Use least privilege principle for RBAC
   - Regularly update container images
   - Scan images for vulnerabilities
