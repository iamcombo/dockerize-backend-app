# Dockerize Nestjs + Postgresql + Redis (Development)

### 1. Create Dockerfile

```docker
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

# Optimized Dockerfile for production

### Use Alpine node images

It's recommended to use the Alpine node images when trying to optimize for image size. Using node:18-alpine instead of node:18 by itself reduces the image size from 1.24GB to 466MB!

### Add a NODE_ENV environment variable

Many libraries have optimizations built in when the NODE_ENV environment variable is set to production, so we can set this environment variable in the Dockerfile build by adding the following line to our Dockerfile:

```docker
ENV NODE_ENV production
```

### Use npm ci instead of npm install

npm recommendeds using npm ci instead of npm install when building your image.

"npm ci is similar to npm install, except it's meant to be used in automated environments such as test platforms, continuous integration, and deployment -- or any situation where you want to make sure you're doing a clean install of your dependencies."

```sh
  RUN npm ci
```

### The USER instruction

By default, if you don't specify a USER instruction in your Dockerfile, the image will run using the root permissions. This is a security risk, so we'll add a USER instruction to our Dockerfile.

The node image we're using already has a user created for us called **node**, so let's use that:

```docker
USER node
```

Whenever you use the COPY instruction, it's also good practice to add a flag to ensure the user has the correct permissions.

You can achieve this by using --chown=node:node whenever you use the COPY instruction, for example:

```docker
  COPY --chown=node:node package*.json ./
```

### Use multistage builds

In your Dockerfile you can define multistage builds which is a way to sequentially build the most optimized image by building multiple images.

Outside of using a small image, multistage builds is where the biggest optimizations can be made.

```docker
  ###################
  # BUILD FOR LOCAL DEVELOPMENT
  ###################

  FROM node:18-alpine As development

  # ... your development build instructions here

  ###################
  # BUILD FOR PRODUCTION
  ###################

  # Base image for production
  FROM node:18-alpine As build

  # ... your build instructions here

  ###################
  # PRODUCTION
  ###################

  # Base image for production
  FROM node:18-alpine As production

  # ... your production instructions here

```

This multistage build uses 3 stages:

1. **development** - This is the stage where we build the image for local development.
2. **build** - This is the stage where we build the image for production.
3. **production** - We copy over the relevant production build files and start the server.

### Putting it all together

```docker
  ###################
  # BUILD FOR LOCAL DEVELOPMENT
  ###################

  FROM node:18-alpine As development

  # Create app directory
  WORKDIR /usr/src/app

  # Copy application dependency manifests to the container image.
  # A wildcard is used to ensure copying both package.json AND package-lock.json (when available).
  # Copying this first prevents re-running npm install on every code change.
  COPY --chown=node:node package*.json ./

  # Install app dependencies using the `npm ci` command instead of `npm install`
  RUN npm ci

  # Bundle app source
  COPY --chown=node:node . .

  # Use the node user from the image (instead of the root user)
  USER node

  ###################
  # BUILD FOR PRODUCTION
  ###################

  FROM node:18-alpine As build

  WORKDIR /usr/src/app

  COPY --chown=node:node package*.json ./

  # In order to run `npm run build` we need access to the Nest CLI which is a dev dependency. In the previous development stage we ran `npm ci` which installed all dependencies, so we can copy over the node_modules directory from the development image
  COPY --chown=node:node --from=development /usr/src/app/node_modules ./node_modules

  COPY --chown=node:node . .

  # Run the build command which creates the production bundle
  RUN npm run build

  # Set NODE_ENV environment variable
  ENV NODE_ENV production

  # Running `npm ci` removes the existing node_modules directory and passing in --only=production ensures that only the production dependencies are installed. This ensures that the node_modules directory is as optimized as possible
  RUN npm ci --only=production && npm cache clean --force

  USER node

  ###################
  # PRODUCTION
  ###################

  FROM node:18-alpine As production

  # Copy the bundled code from the build stage to the production image
  COPY --chown=node:node --from=build /usr/src/app/node_modules ./node_modules
  COPY --chown=node:node --from=build /usr/src/app/dist ./dist

  # Start the server using the production build
  CMD [ "node", "dist/main.js" ]
```

Similar to a **.gitignore** file, we can add a **.dockerignore** file which will prevent certain files from being included in the image build.

```sh
  # .dockerignore
  Dockerfile
  .dockerignore
  node_modules
  npm-debug.log
  dist
```
