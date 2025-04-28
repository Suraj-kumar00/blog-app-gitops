# Docker Deployment Guide

This guide explains how to build, run, and deploy the BlogPosts application using Docker and Docker Compose.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (version 20.10.0 or later)
- [Docker Compose](https://docs.docker.com/compose/install/) (version 2.0.0 or later)

## Quick Start

1. Clone the repository:

   ```bash
   git clone https://github.com/Suraj-kumar00/blog-posts.git
   cd blog-posts
   ```

2. Create a `.env` file with the necessary environment variables:

   ```bash
   cp .env.example .env  # If .env.example exists
   # Edit .env with your preferred text editor
   ```

3. Build and start the application:

   ```bash
   docker-compose up -d
   ```

4. Access the application at http://localhost:3000

## Environment Variables

The following environment variables can be set in your `.env` file:

```
POSTGRES_DB=blog_production
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password
POSTGRES_HOST=db
RAILS_ENV=production
RAILS_MASTER_KEY=your_master_key
REDIS_URL=redis://redis:6379/1
```

## Building the Docker Image

### Using Docker Compose

```bash
docker-compose build
```

### Building the Image Directly

```bash
docker build -t blog-app .
```

## Running the Application

### Using Docker Compose (Recommended)

Start all services:

```bash
docker-compose up -d
```

Stop all services:

```bash
docker-compose down
```

### Running Container Commands

Execute Rails commands:

```bash
docker-compose exec web rails db:migrate
docker-compose exec web rails console
```

## Container Structure

The application uses a multi-container setup:

- `web`: The Rails application
- `db`: PostgreSQL database
- `redis`: Redis for caching and background jobs

## Docker Compose Configuration

The `docker-compose.yml` file defines:

1. **Web service**: Uses multi-stage build for smaller image size
2. **Database service**: PostgreSQL with persistent volume
3. **Redis service**: For caching and background jobs
4. **Networking**: Containers communicate through an internal network
5. **Volumes**: Persistent storage for database and application files
6. **Healthchecks**: Monitors service health status

## Dockerfile Explanation

Our `Dockerfile` uses a multi-stage build approach:

1. **Builder stage**:

   - Installs build dependencies
   - Installs application gems
   - Precompiles assets

2. **Final stage**:
   - Uses a slim base image for smaller size
   - Copies only necessary files from the builder stage
   - Includes minimal runtime dependencies

## Production Deployment Considerations

For production deployments:

1. **Security**:

   - Use strong, unique passwords for database credentials
   - Store sensitive information in environment variables
   - Never commit `.env` files to version control

2. **SSL/TLS**:

   - Add a reverse proxy like Nginx for SSL termination
   - Configure appropriate security headers

3. **Scaling**:

   - Consider using Docker Swarm or Kubernetes for orchestration
   - Implement load balancing for high availability

4. **Monitoring**:
   - Set up health checks and monitoring tools
   - Configure logging for observability

## Troubleshooting

### Common Issues

1. **Database connection issues**:

   ```bash
   docker-compose logs db    # Check database logs
   docker-compose exec db psql -U postgres  # Connect to the database
   ```

2. **Web server not starting**:

   ```bash
   docker-compose logs web   # Check web server logs
   ```

3. **Permission issues with volumes**:
   ```bash
   docker-compose down -v    # Remove volumes
   docker-compose up -d      # Recreate volumes
   ```

## Performance Optimization

- Use Docker volume caching for faster builds
- Configure appropriate memory limits in `docker-compose.yml`
- Use multi-stage builds to reduce image size
