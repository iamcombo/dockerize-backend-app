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
    env_file:
      - .env
    ports:
      - "3030:3030"
    # Run a command against the development stage of the image
    command: npm run start:dev
    depends_on:
      - postgres-db
      - redis

  redis:
    container_name: redis
    image: redis
    restart: unless-stopped
    ports:
      - "6379:6379"

  postgres-db:
    container_name: postgres-db
    image: postgres:16
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - ./postgres-data:/var/lib/postgresql/data
```

Let's highlight a few important parts of this file:

- The **target: development** points to the **development** stage within the Dockerfile. This is great because it means it will ignore the other stages which are purposed for production and not required to run locally.
- The **volumes** section enables the data to be persisted and is what makes the hot reloading possible.
- The **env_file** section tells Docker to load the .env file into the container. Important if you have any environment variables set in your NestJS app.
- The **command** section tells Docker to run the **yarn run start:dev** command against the image built in the **development** stage

```sh
  # Execute the instructions in the docker-compose.yml file.
  $ docker compose up -d
```

**Please note** - if your NestJS image already exists (for example, if you tested building the full image in the Dockerfile above), you can run docker-compose up -d --build to rebuild the image.
