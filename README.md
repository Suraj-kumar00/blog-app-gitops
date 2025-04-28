# BlogPosts - A Ruby on Rails Application

BlogPosts is a simple blog application built with Ruby on Rails that allows users to create, read, update, and delete blog posts.

## Features

- Create, view, edit, and delete blog posts
- Modern, responsive UI with dark mode support
- Docker-ready for easy deployment

## Technology Stack

- **Ruby version**: 3.2.0
- **Rails version**: 7.x
- **Database**: PostgreSQL 14
- **Frontend**: Tailwind CSS, Font Awesome
- **Cache**: Redis
- **Container**: Docker and Docker Compose

## Requirements

To run this application locally, you'll need:

- Ruby 3.2.0
- PostgreSQL 14
- Node.js and Yarn
- Redis (optional for caching)

## Architecture diagram

![architecure diagram](public/blog-app-gitops-architecture.png)

## DevOps practices

- **Containerization**:

  - Dockerize Ruby on Rails app and PostgreSQL DB in separate containers.

- **Orchestration**:

  - Deploy containers on Kubernetes cluster (Minikube/K3d).
  - Use StatefulSet for PostgreSQL.
  - Set up Ingress Controller or Service Mesh for routing.

- **GitOps**:

  - Manage Kubernetes deployments using ArgoCD.
  - Sync deployments from a **private GitHub repository**.
  - Store all YAMLs and ArgoCD configs in GitHub.

- **CI/CD Pipeline**:

  - Set up Tekton Pipelines for:
    - Cloning source code from a **public repository**.
    - Building Docker images.
    - Pushing images to Docker Hub.
  - Manual pipeline execution via Tekton Dashboard.

- **Developer Workflow**:
  - Developer pushes code to **private GitHub repo**.
  - ArgoCD auto-deploys the updated application to Kubernetes.

## Local Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/blog-posts.git
   cd blog-posts
   ```

2. Install dependencies:

   ```bash
   bundle install
   yarn install
   ```

3. Setup the database:

   ```bash
   bundle exec rails db:create
   bundle exec rails db:migrate
   bundle exec rails db:seed # Optional: adds sample data
   ```

4. Start the server:

   ```bash
   bundle exec rails server
   ```

5. Visit http://localhost:3000 in your browser

## Environment Variables

Create a `.env` file in the root directory with the following variables:

```
POSTGRES_DB=blog_development
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_HOST=localhost
RAILS_ENV=development
RAILS_MASTER_KEY=your_master_key
```

## Docker Deployment

To run the application with Docker, please refer to [DOCKER.md](DOCKER.md) for detailed instructions.

## Running Tests

```bash
bundle exec rspec
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is open source and available under the [MIT License](LICENSE).
