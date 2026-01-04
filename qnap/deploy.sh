#!/bin/sh

source .env

# Ensure we have a folder for the database
if [ ! -d $NAS_MARIADB_PATH ]; then
    echo "Creating database folder"
    mkdir -p $NAS_MARIADB_PATH
fi

# Ensure we have a folder for the database backups
if [ ! -d $NAS_MARIADB_BACKUPS_PATH ]; then
    echo "Creating database backup folder"
    mkdir -p $NAS_MARIADB_BACKUPS_PATH
fi

# Ensure we have a folder for the user files
if [ ! -d $NAS_FILES_PATH ]; then
    echo "Creating folder for user files"
    mkdir -p $NAS_FILES_PATH
fi

# Ensure we have a folder for the user file backups
if [ ! -d $NAS_FILES_BACKUPS_PATH ]; then
    echo "Creating folder for user file backups"
    mkdir -p $NAS_FILES_BACKUPS_PATH
fi

# Ensure we have a folder for the SSL certificate backup
if [ ! -d $NAS_CERTS_BACKUP_PATH ]; then
    echo "Creating folder for SSL certificate backup"
    mkdir -p $NAS_CERTS_BACKUP_PATH
fi

docker network create traefik-network
docker network create owncloud-network

# Deploy ownCloud using Docker Compose
docker compose -p owncloud up -d
