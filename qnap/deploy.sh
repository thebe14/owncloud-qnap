#!/bin/sh

# Ensure we have a folder for the database
if [ ! -d /share/CACHEDEV1_DATA/ownCloud/database ]; then
    echo "Creating database folder"
    mkdir -p /share/CACHEDEV1_DATA/ownCloud/database
fi

# Ensure we have a folder for the database backups
if [ ! -d /share/Backup/ownCloud/database ]; then
    echo "Creating database backup folder"
    mkdir -p /share/Backup/ownCloud/database
fi

# Ensure we have a folder for the user files
if [ ! -d /share/CACHEDEV1_DATA/ownCloud/files ]; then
    echo "Creating folder for user files"
    mkdir -p /share/CACHEDEV1_DATA/ownCloud/files
fi

# Ensure we have a folder for the user file backups
if [ ! -d /share/Backup/ownCloud/files ]; then
    echo "Creating folder for user file backups"
    mkdir -p /share/Backup/ownCloud/files
fi

docker network create traefik-network
docker network create owncloud-network

# Deploy ownCloud using Docker Compose
docker compose -p owncloud up -d
