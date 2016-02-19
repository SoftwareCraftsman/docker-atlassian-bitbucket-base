# README

[![](https://badge.imagelayers.io/softwarecraftsmen/atlassian-bitbucket-base:latest.svg)](https://imagelayers.io/?images=softwarecraftsmen/atlassian-bitbucket-base:latest)

This image provides a [Bitbucket Server](https://www.atlassian.com/software/bitbucket/server) with an embedded database which is sufficient for demo and evaluation purpose. However, for production it is advised to use one of the [supported external databases](https://confluence.atlassian.com/bitbucketserver/connecting-bitbucket-server-to-an-external-database-776640378.html) (e.g. PostgreSQL). This image has a yet minimalistic support for configuring such a database by extending from this image.

# How to use this images

## Prepare a docker host

```sh
docker-machine create --driver virtualbox atlassian <1>
docker-machine start atlassian <2>
eval `docker-machine env atlassian` <3>
```

1. Create a docker machine (once only)
2. Start the docker machine
3. Setup the docker client to use the docker-machine

## Run a Bitbucket Server instance

```sh
docker pull softwarecraftsmen/atlassian-bitbucket-base
docker run -d --name bitbucketserver -p 8080:8080 atlassian-bitbucket-base
```

Startup after creating a container takes some time as the installation and configuration process is continuing.
So be patient until the start page for license registration can be opened.

To open Bitbucket Server start page on Mac OSX run from the shell:
```
open http://`docker-machine ip atlassian`:8080
```

## Extend this image

For replacing the internal embedded database we just have to add a [bitbucket.properties](https://confluence.atlassian.com/bitbucketserver/bitbucket-server-config-properties-776640155.html) file.

```
jdbc.driver=org.postgresql.Driver
jdbc.url=jdbc:postgresql://postgresdb:5432/bitbucket
```

The extending image has to add this file like

```sh
ADD bitbucket.properties bitbucket.properties
```

If required we can add more properties to [bitbucket.properties](https://confluence.atlassian.com/bitbucketserver/bitbucket-server-config-properties-776640155.html).

This base image offers a few environment variable especially for setting sensitive data such as password or license keys. These are automatically written into their respective property keys in `bitbucket.properties`. These are better set through environment variables during container start rather than coding them into `bitbucket.properties`.

## Environment Variables

During the first start of the container a few environment variables are considered to customize the container.

The subset of supported [bitbucket. properties](https://confluence.atlassian.com/bitbucketserver/bitbucket-server-config-properties-776640155.html) is as follows.

### `BITBUCKET_LICENSE`

Required, no default provided

### `BITBUCKET_USER`

Optional, default `bitbucket` provided

### `BITBUCKET_PASSWORD`

Optional, default `bitbucket` provided

### `BITBUCKET_JDBC_USER`

Optional, default `bitbucket` provided

### `BITBUCKET_JDBC_PASSWORD`

Optional, default `bitbucket` provided

## Connect to a PostgreSQL database

Work in progress!

Items to complete
* create network bitbucket
* create postgresql container with bitbucket schema, add to network bitbucket
* create bitbucket container, add to network bitbucket
