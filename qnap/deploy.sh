#!/bin/bash

docker network create traefik-network
docker network create owncloud-network

# Deploy ownCloud using Docker Compose
docker compose -p owncloud up -d
