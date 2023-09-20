<div align="center">
  
```sh
   ___ ____    ____   ___   ____ _  _______ ____  
  |_ _/ ___|  |  _ \ / _ \ / ___| |/ / ____|  _ \ 
   | |\___ \  | | | | | | | |   | ' /|  _| | |_) |
   | | ___) | | |_| | |_| | |___| . \| |___|  _ < 
  |___|____/  |____/ \___/ \____|_|\_\_____|_| \_\

 a CLI utility for orchestrating Docker based developer environments

```
</div>

## Supported Operating Systems
* Ubuntu
* windows (available soon)
* Mac OS (available soon)

## Prerequisites
* Docker - [Download & Install](https://docs.docker.com/get-docker/#installation)
* Compose - [Download & Install](https://docs.docker.com/compose/install/)
* Mutagen - [Download & Install](https://mutagen.io/) (required for environments leveraging sync sessions on Mac OS)

## Installation
1. Cloning the repository

* Open a Terminal and type (or copy / paste) the command below in, then press Enter
```sh
sudo mkdir /opt/isdocker
sudo chown $(whoami) /opt/isdocker
git clone -b master https://github.com/defenseoftheancients/isdocker.git /opt/isdocker
echo 'alias isdocker="/opt/isdocker/bin/isdocker"' >> ~/.bashrc
source ~/.bashrc
```
2. Installing via Homebrew
```sh
brew install defenseoftheancients/isdocker/isdocker
```
or
```sh
brew tap defenseoftheancients/isdocker
brew install isdocker
```

## Usage

* **_Global services_**

| Command | Description |
| --- | --- |
| `isdocker svc up` | Builds, (re)creates, starts for global services. |
| `isdocker svc down` | Stops containers and removes containers, networks, volumes, and images created by up |

* **_Adding configuration environment file_**

| Command | Description |
| --- | --- |
| `isdocker env-init projectName` | Configure environment by adding '.env' file to the current working directory |

* **_Controls an environment_**

| Command | Description |
| --- | --- |
| `isdocker env up` | Starting a stopped environment |
| `isdocker env down` | Stopping a running environment |

* **_Add configuration files for the specified images_**

| Command | Description |
| --- | --- |
| `isdocker config imageNames` | Add configuration files and isdocker-env.yml for the specified images to .isdocker directory |

* **_Launches into a shell_**

| Command | Description |
| --- | --- |
| `isdocker shell `| Launches into a shell within the current project environment |

* **_Interacts with the db service_**

| Command | Description |
| --- | --- |
| `isdocker db import absolutePathSQLFile`|  Reads data from stdin and loads it into the current project's mysql database|

* **_Show version_**

| Command | Description |
| --- | --- |
| `isdocker version`|  Show version information |

## Customizing An Environment

To configure your project with a non-default PHP version, add the following to the project’s .env file and run isdocker env up to re-create the affected containers:
PHP_VERSION=8.2
The versions of MariaDB, Elasticsearch, Varnish, Redis, NodeJS and Composer may also be similarly configured using variables in the .env file:
* COMPOSER_VERSION
* DATABASE_ENGINE_VERSION
* SEARCH_ENGINE_VERSION
* VARNISH_VERSION
* RABBITMQ_VERSION
* REDIS_VERSION
* COMPOSER_VERSION

Start of some environments could be skipped by using variables in .env file:

* ISDOCKER_NGINX=1
* ISDOCKER_PHP=1
* ISDOCKER_CLI=1
* ISDOCKER_DB=1
* ISDOCKER_SEARCHENGINE=1
* ISDOCKER_ADMINER=0
* ISDOCKER_CRON=0
* ISDOCKER_REDIS=0
* ...

### 1. Docker Specific Customizations
To override default docker settings, add a custom configuration file in your project root folder: /.isdocker/isdocker-env.yml This file will be merged with the default environment configuration

### 2. Example
Example 1: Configure one image
```sh
isdocker config php
```
php-custom.ini and smtp files will copy into .isdocker directory

```
├── .env 
└── .isdocker
    ├── isdocker-env.yml
    ├── php-custom.ini
    └── smtp
```

isdocker-env.yml should look like this:
```yml
version: '3.8'
services:
  php:
    volumes:
        - ./.isdocker/php-custom.ini:/usr/local/etc/php/conf.d/zzz-custom.ini:ro
        - ./.isdocker/smtp:/etc/msmtprc:ro

```

Example 2: Configure multiple image
```sh
isdocker config nginx php cli db
```

.isdocker directory
```
├── .env
└── .isdocker
    ├── blackfire.env
    ├── isdocker-env.yml
    ├── mysql.cnf
    ├── nginx-sites.conf
    ├── php-custom.ini
    └── smtp
```
isdocker-env.yml should look like this:
```yml
version: '3.8'

services:
    db:
        volumes:
        - ./.isdocker/mysql.cnf:/etc/mysql/conf.d/custom.cnf:ro
    cli:
        env_file: ./.isdocker/blackfire.env
        volumes:
        - ./.isdocker/php-custom.ini:/usr/local/etc/php/conf.d/zzz-custom.ini:ro
        - ./.isdocker/smtp:/etc/msmtprc:ro
    nginx:
        volumes:
        - ./.isdocker/nginx-sites.conf:/etc/nginx/templates/default.conf.template:ro
    php:
        volumes:
        - ./.isdocker/php-custom.ini:/usr/local/etc/php/conf.d/zzz-custom.ini:ro
        - ./.isdocker/smtp:/etc/msmtprc:ro

```

## Rereference
* [Warden](https://github.com/wardenenv/warden)
