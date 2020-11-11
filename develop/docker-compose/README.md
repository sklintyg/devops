# Pre-Req
Docker!

The fact that Docker is required should be pretty obvious. On linux this will work fine "out-of-the-box",
but windows users are recommended to use Docker with `WSL2` as the backing engine.

To use WSL2 on Windows 10 you will need at least the 20H1 (2004) update,
or a minor build number 1049 or higher on Windows builds 18362 or 18363.

Check your version by pressing `Win` and type `winver` followed by `enter`.
Check the `OS Build` information.
Ex: _(OS Build 18363.1139)_ is a valid version.

Once one of these versions are installed, `WSL2` can be installed or upgraded from `WSL`.

* https://docs.microsoft.com/en-us/windows/wsl/install-win10
    * `Ubuntu` is the recommended linux distribution

The next step is to install Docker Desktop (Stable version). Choose WSL2 as engine and skip Hyper-V.

* https://docs.docker.com/docker-for-windows/install/

## What's included
The docker compose script in the directory includes the following infrastructure applications:
* Mysql (3306)
* Redis (6379)
* AMQ (1883, 5675, 8861, 61613, 61614, 61616)
* NGINX (80, 443) 

## Usage
This repository must be checked out with the correct branch (as of now `release/2021-1`).

Use a console of your choice (PowerShell, Ubuntu in WSL2, Git Bash etc.) and go to the directory containing this README.me file.
Then use the following commands to start and stop the containers:

* `docker-compose up -d` (start as deamon)
* `docker-compose up` (will lock console and use it to print container logs)
* `docker-compose down`


_**Note:** Windows sends a warning if the docker-compose directory (i.e. this directory), is mounted on the windows filesystem
but this can be ignored for now._

## ActiveMQ GUI
https://amq.localtest.me/admin (admin/admin)