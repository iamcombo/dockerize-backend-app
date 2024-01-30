######################################
# BUILD FOR LOCAL DEVELOPMENT
######################################

# Base image for devlopment
FROM node:18-alpine As development

# TODO: your development build instructions here

######################################
# BUILD FOR PRODUCTION
######################################

# Base image for production
FROM node:18-alpine As build

# TODO: your build instructions here

######################################
# PRODUCTION
######################################

# Base image for production
FROM node:18-alpine As production

# TODO: your production instructions here