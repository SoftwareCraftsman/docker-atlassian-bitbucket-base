# README

Docker Image [![](https://images.microbadger.com/badges/image/softwarecraftsmen/atlassian-bitbucket-base.svg)](https://microbadger.com/images/softwarecraftsmen/atlassian-bitbucket-base "atlassian-bitbucket-base image layers")  [![](https://images.microbadger.com/badges/version/softwarecraftsmen/atlassian-bitbucket-base.svg)](https://microbadger.com/images/softwarecraftsmen/atlassian-bitbucket-base "atlassian-bitbucket-base image layers")

This image provides a [Bitbucket Server](https://www.atlassian.com/software/bitbucket/server) with an embedded database which is sufficient for demo and evaluation purpose. However, for production it is advised to use one of the [supported external databases](https://confluence.atlassian.com/bitbucketserver/connecting-bitbucket-server-to-an-external-database-776640378.html) (e.g. PostgreSQL). This image has a yet minimalistic support for configuring such a database by extending from this image.

# How to use this image

## Prepare a docker host

```sh
docker-machine create --driver virtualbox atlassian <1>
docker-machine start atlassian <2>
eval `docker-machine env atlassian` <3>
```

1. Create a docker machine (once only)
2. Start the docker machine
3. Setup the docker client to use the docker-machine

## Build the image

.Build with VCS information built-in as docker label
```sh
docker build --build-arg VCS_REF=`git rev-parse --short HEAD` -t softwarecraftsmen/atlassian-bitbucket-base .
```

### Publish to Docker Hub

Tag the git repository using the bitbucket version number as tag
```
git tag <bitbucket-version>
git push origin master --tags
```


## Run a Bitbucket Server instance

```sh
docker pull softwarecraftsmen/atlassian-bitbucket-base
docker run -d --name bitbucket-server -p 7990:7990 softwarecraftsmen/atlassian-bitbucket-base
```

The first time container startup takes some time as the installation and configuration process is continuing.
So be patient until the start page for license registration can be opened.

To open Bitbucket Server start page on Mac OSX run from the shell:
```
open http://`docker-machine ip atlassian`:7990
```

While the setup completes, you will be asked for an administrator account setup. 
The username and password must match the settings provided by the environment variables `BITBUCKET_USER` and `BITBUCKET_PASSWORD` 

## Extend this image

### Use an external database

For replacing the internal embedded database we just have to add a [bitbucket.properties](https://confluence.atlassian.com/bitbucketserver/bitbucket-server-config-properties-776640155.html) file to the image. It will be moved to `$BITBUCKET_HOME/shared/`.

```
jdbc.driver=org.postgresql.Driver
jdbc.url=jdbc:postgresql://postgresdb:5432/bitbucket
```

The extending image must add this file in its `Dockerfile` like

```sh
ADD bitbucket.properties bitbucket.properties
```

This base image offers a few environment variables especially for setting sensitive settings such as password or license keys that should not be committed to the repository. These are automatically written into their respective property keys in `bitbucket.properties`.
These are better set through environment variables and passed to the container rather than hard coded them into `bitbucket.properties`.

## Environment Variables

During the first start of the container a few environment variables are considered to customize the container.

The subset of supported [bitbucket.properties](https://confluence.atlassian.com/bitbucketserver/bitbucket-server-config-properties-776640155.html) is as follows.

### `BITBUCKET_LICENSE`

Required, no default provided. Maps to `setup.license`.

### `BITBUCKET_USER`

Optional, default `bitbucket` provided. Maps to `setup.sysadmin.username`.

### `BITBUCKET_PASSWORD`

Optional, default `bitbucket` provided. Maps to `setup.sysadmin.password`.

### `BITBUCKET_JDBC_USER`

Optional, default `bitbucket` provided. Maps to `jdbc.user`.

### `BITBUCKET_JDBC_PASSWORD`

Optional, default `bitbucket` provided. Maps to `jdbc.password`.


## Backup

See [Using Bitbucket Server DIY Backup](https://confluence.atlassian.com/bitbucketserver/using-bitbucket-server-diy-backup-776640056.html).
