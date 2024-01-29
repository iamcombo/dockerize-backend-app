# #######################################
# ##### BUILD FOR LOCAL DEVELOPMENT #####
# #######################################

FROM node:18-alpine As development

# Set a work directory in the container
WORKDIR /usr/src/app

# Copy application dependency manifests to the container image 
COPY package*.json yarn.lock ./

# Install application depenency
RUN yarn install

# Copy the rest of the application code to container
COPY . .

# Build the application
RUN yarn run build


# #####################################
# ####### BUILD FOR PRODUCTION ########
# #####################################
FROM node:18-alpine As build

# Set a work directory in the container
WORKDIR /usr/src/app

# Copy application dependency manifests to the container image 
COPY package*.json yarn.lock ./

# Install application depenency
RUN yarn install

# Copy the rest of the application code to container
COPY . .

# Build the application
RUN yarn run build

FROM node:18 As Production

# Set a work directory in the container
WORKDIR /usr/src/app

# Copy the build directory from the development stage
COPY --from=build /usr/src/app/dist ./dist

# Copy application dependency manifests to the container image 
COPY package*.json yarn.lcok ./

# Install application depenency
RUN yarn install --only=production

EXPOSE 3000

CMD [ "node", "dist/main.js" ]