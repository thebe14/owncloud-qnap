ARG OWNCLOUD_MARIADB_IMAGE_TAG
FROM $OWNCLOUD_MARIADB_IMAGE_TAG

# Install jq
RUN apt-get update -y && \
    apt-get install -y jq && \
    apt-get -q clean && \
    rm -rf /var/lib/apt/lists/*

CMD sh -c 'sleep $BACKUP_INIT_SLEEP && \
    while true; do \
      mariadb-dump -h mariadb -u $OWNCLOUD_DB_USER -p"$OWNCLOUD_DB_PASSWORD" $OWNCLOUD_DB_NAME | gzip > "$MARIADB_BACKUPS_PATH/$MARIADB_BACKUP_NAME-$(date '+%Y-%m-%d_%H-%M').gz" && \
      tar -zcpf $DATA_BACKUPS_PATH/$DATA_BACKUP_NAME-$(date "+%Y-%m-%d_%H-%M").tar.gz $DATA_PATH && \
      find $MARIADB_BACKUPS_PATH -type f -mtime +$MARIADB_BACKUP_PRUNE_DAYS | xargs rm -f && \
      find $DATA_BACKUPS_PATH -type f -mtime +$DATA_BACKUP_PRUNE_DAYS | xargs rm -f && \
      jq -r ".letsencrypt.Certificates[] | select(.domain.main==\"$OWNCLOUD_HOSTNAME\") | .certificate" /usr/traefik/acme/acme.json | base64 -d > $CERTS_PATH/cert.pem; \
      jq -r ".letsencrypt.Certificates[] | select(.domain.main==\"$OWNCLOUD_HOSTNAME\") | .key" /usr/traefik/acme/acme.json | base64 -d > $CERTS_PATH/key.pem; \
      sleep $BACKUP_INTERVAL; done'
