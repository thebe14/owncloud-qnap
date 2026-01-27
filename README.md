![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/thebe14/owncloud-qnap?color=darkcyan&label=Release)
![GitHub issues](https://img.shields.io/github/issues/thebe14/owncloud-qnap?label=Issues)
![GitHub issue custom search in repo](https://img.shields.io/github/issues-search/thebe14/owncloud-qnap?label=Bugs&color=red&query=is%3Aopen%20label%3Abug)

# ownCloud with Let's Encrypt on QNAP NAS

[ownCloud](https://owncloud.com/) is the ultimate file management platform,
essential for enterprise-grade file synchronization and sharing, expertly
tailored to meet your personal and business needs. Hosting your own instance
of ownCloud means you will have your own, private ~~Dropbox~~/~~OneDrive~~
cloud storage.

Most modern NAS models can run applications, either curated by the NAS
manufacturer or based on Docker containers. However, the ownCloud application
in the QNAP App Center is either old or was removed in later QTS versions.
This is a guide on installing ownCloud on a [QNAP NAS](https://www.qnap.com)
using Docker Compose.

The challenge on hosting your own ownCloud instance is that it only supports
unencrypted connections. Thus, unless you buy and configure a certificate for
the hostname on which you expose your ownCloud to the world, and employ a method
to negotiate and establish an encrypted connection (over the HTTPS protocol),
all browsers, desktop clients, and mobile apps you use to connect to it will
complain (rightfully so) that the connection is insecure.

We will use [Traefik](https://github.com/traefik/traefik) as our reverse
proxy between ownCloud and the world. It will obtain free cryptographic
certificates from [Let’s Encrypt](https://letsencrypt.org) for your domain
names, will establish encrypted connections with clients, and will forward
secure requests to the corresponding services based on those domains.

Let's Encrypt [validates](https://letsencrypt.org/how-it-works/)
that the hostname for which you are requesting a certificate actually points
to your service, before it issues a certificate. Multiple
[validation methods](https://tools.ietf.org/html/rfc8555)
are supported, the easiest is via an agent that puts a temporary file in a
well-known path on your website that Let's Encrypt can fetch and validate.
Traefik supports this validation method.

Traefik will be configured to generate/renew certificates via TLS challenge,
which means you do not have to open an HTTPS port for your ownCloud instance,
and another HTTP port for the Let's Encrypt validation, instead both can happen
via the same HTTPS port.

>💡 If you experiment with this project and re-deploy ownCloud repeatedly,
> make sure you keep the volume `traefik-certificates`, it contains the
> certificates issued by Let's Encrypt. If you don't do this, you risk exceeding
> the [rate limits](https://letsencrypt.org/docs/rate-limits/) of Let's Encrypt,
> which is 5 certificates every 7 days, as of this commit. This means after you
> request 5 certificates, you will have to either wait 7 days or change the
> hostnames you are using for ownCloud and Traefik.

Finally, a comment about using volumes. Instead of just declaring volumes that
Docker creates in a random place to store the various parts of ownCloud's data,
we will carefully create folders for them, telling Docker to map these into the
right place in the ownCloud container.

## 1. Configuration

First and foremost, you must configure your router or ingress to forward port
443 (HTTPS) to port 8099 on your NAS.

>💡 In case you are already publishing someting on the default HTTPS port 443,
> you can use any other port, say `1234` but you will have to configure your
> ownCloud clients to connect to `https://owncloud.mydomain.org:1234` instead
> of the default `https://owncloud.mydomain.org`.

SSH to your NAS, create a folder `owncloud` in your home directory, and bring
the content of `/qnap` there. The result should look like this:

![files in my homedir](./ssh-checkout.jpg)

>❗ You must edit the file `.env` to configure your ownCloud instance before
> installation.

Decide the domain name where your ownCloud will be exposed to the world, and
change these environment variables:

- **OWNCLOUD_HOSTNAME** is the fully qualified hostname for your ownCloud
instance. This must resolve to an IP of your NAS, or more likely your router,
which in turn has forwarding rules to your NAS.
- **OWNCLOUD_ADMIN_USERNAME** is the username for the ownCloud administrator
- **OWNCLOUD_ADMIN_PASSWORD** is the password of the administrator user

Decide the domain name where the Traefic proxy's dashboard will be exposed to
the world (if at all), and change these environment variables:

- **TRAEFIK_HOSTNAME** is the fully qualified hostname for your ownCloud
instance, usually the same as **OWNCLOUD_HOSTNAME**
- **TRAEFIK_BASIC_AUTH** is the username and password of the Traefic
administratrator, in the form `username:password` where the password is encoded
using MD5, SHA1, or BCrypt. You can encode your password
[here](https://hostingcanada.org/htpasswd-generator/).

Decide how often you want your ownCloud metadata and the user files backed up,
and how long to keep the backups:

- **BACKUP_INTERVAL** is how often you want to backup your ownCloud data
- **MARIADB_BACKUP_PRUNE_DAYS** is how many days of database backups to keep
- **DATA_BACKUP_PRUNE_DAYS** is how many days of user file backups to keep

Decide where ownCloud's data should be stored and backed up, and create
dedicated folders for them.

On a QNAP NAS there is usually one volume, sometimes more. 
On my NAS the only volume is mounted under `/share/CACHEDEV1_DATA`, you should
see all the shared folders there:

![my shared folders via command line](./ssh-shares.jpg)

There are also symlinks under `/share` to all shared folders, we will take
advantage of these to define where to backup up data in this ownCloud instance.

You can confirm you are in the right place if these folders match your shared
folders:

![my shared folders](./shared-folders.jpg)

From the SSH command line, create a folder `ownCloud` in the root of your volume,
then create folders `database`, `files`, and `ssl` under it:

![ownCloud holder folder](./ssh-owncloud.jpg)

>❗ If you create the ownCloud root folder from the Control Panel, that will
> create a shared folder, allowing access to the user files via that share.
> This is a bad idea. Never touch the user files directly, it will corrupt your
> ownCloud installation.

In summary, you will have to create the folders below and change the environment
variables to point to them:

- **NAS_MARIADB_PATH** is where the ownCloud metadata is kept (in a MariaDB database)
- **NAS_MARIADB_BACKUPS_PATH** is where the database is backed up periodically (see below)
- **NAS_FILES_PATH** is where the actual user files are kept
- **NAS_FILES_BACKUPS_PATH** is where the user files are backed up periodically (see below)
- **NAS_CERTS_BACKUPS_PATH** is where the SSL certificate is backed up periodically (see below)

After you created these folders and set the environment variables to point to them,
you can proceed to install ownCloud.

>💡 I am storing the backups under a shared folder `Backup`, to facilitate syncing
> the backups off-site.

## 2. Installation

Switch to your home directory and make the shell scripts executable, by running
the following command:

```bash
chmod +x *.sh
```

To deploy, use the following script:

```bash
sudo ./deploy.sh
```

If you prefer to deploy manually, first create the networks for your services:

```bash
sudo docker network create traefik-network
sudo docker network create owncloud-network
```

Then make sure each folder described in the [configuration](#1-configuration)
section exists (the script `./deploy.sh` would create these for you, based on
the variables you defined).

You can then deploy ownCloud using Docker Compose:

```bash
sudo docker compose -p owncloud up -d
```

> Note that the `.env` file should be in the same directory as `docker-compose.yml`.

## 3. Backups

The `backups` container is responsible for the following:

1. **Database Backup**: Creates compressed backups of the MariaDB database
using `pg_dump`. Customizable backup path, filename pattern, and schedule
through variables like `MARIADB_BACKUPS_PATH`, `MARIADB_BACKUP_NAME`,
and `BACKUP_INTERVAL`.

2. **Application Data Backup**: Compresses and stores backups of the application
data on the same schedule. Controlled via variables such as `DATA_BACKUPS_PATH`,
`DATA_BACKUP_NAME`, and `BACKUP_INTERVAL`.

3. **Backup Pruning**: Periodically removes backups exceeding a specified age to
manage storage. Customizable pruning schedule and age threshold with
`MARIADB_BACKUP_PRUNE_DAYS` and `DATA_BACKUP_PRUNE_DAYS`.

4. Exporting the SSL certificate (and key) obtained from Let's Encrypt for the
configured domain. This is useful if you want to reuse it for other services
that you expose of the same domain name.

By utilizing this container, consistent and automated backups of the essential
components of your instance are ensured. Moreover, efficient management of
backup storage and tailored backup routines can be achieved through easy and
flexible configuration using environment variables.

> The `backups` container is technically a dummy database instance, which is
> never used. Basing this container on a MariaDB image ensures that the MariaDB
> utilities to backup and restore the database are available in the container.

To take advantage of the backups this container creates periodically, you can
run the restore scripts from a SSH session to your QNAP.

### 3.1 Restoring the database

This script facilitates the restoration of a database backup:

1. **Identify Containers**: It first identifies the service and backups
containers by name, finding the appropriate container IDs.

2. **List Backups**: Displays all available database backups located at the
specified backup path.

3. **Select Backup**: Prompts the user to copy and paste the desired backup
name from the list to restore the database.

4. **Stop Service**: Temporarily stops the service to ensure data consistency
during restoration.

5. **Restore Database**: Executes a sequence of commands to drop the current
database, create a new one, and restore it from the selected compressed backup
file.

6. **Start Service**: Restarts the service after the restoration is completed.

Usage of this script ensures a controlled and guided process to restore the
database from an existing backup.

### 3.2 Restoring the application data

This script is designed to restore the application data:

1. **Identify Containers**: Similarly to the database restore script, it
identifies the service and backups containers by name.

2. **List Application Data Backups**: Displays all available application data
backups at the specified backup path.

3. **Select Backup**: Asks the user to copy and paste the desired backup name
for application data restoration.

4. **Stop Service**: Stops the service to prevent any conflicts during the
restore process.

5. **Restore Application Data**: Removes the current application data and
then extracts the selected backup to the appropriate application data path.

6. **Start Service**: Restarts the service after the application data has
been successfully restored.

By utilizing this script, you can efficiently restore application data from
an existing backup while ensuring proper coordination with the running service.

## Authors

Based on work of [Vladimir Mikhalev](https://www.linkedin.com/in/heyvaldemar/),
adapted for QNAP NAS running QTS 5.x by [Levente Farkas](https://github.com/thebe14).
