# Dockerize Nestjs + Postgresql + Redis (Development)

### 1. Create Dockerfile

```yaml
  FROM node:18-alpine As development

  # Create app directory
  WORKDIR /usr/src/app

  # Copy application dependency manifests to the container image
  COPY package*.json yarn.lock ./

  # Install application dependencies
  RUN yarn install

  # Copy the rest of the application code to the container
  COPY . .

  # Build the application (if needed)
  RUN yarn run build

  CMD ["yarn", "run", "start:dev"]
```

### 2. Create docker-compose.yml file

```yaml
version: 3
services:
  app:
    container_name: backend-app
    build:
      context: .
      dockerfile: Dockerfile
      # Only will build development stage from our dockerfile
      target: development
    ports:
      - "3030:3030"
    depends_on:
      - postgres-db
      - redis

  postgres-db:
    container_name: postgres-db
    image: postgres:16
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: your_username
      POSTGRES_PASSWORD: your_password
      POSTGRES_DB: your_database
    volumes:
      - ./postgres-data:/var/lib/postgresql/data

  redis:
    container_name: redis
    image: redis
    ports:
      - "5432:5432"
```
