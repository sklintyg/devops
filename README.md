# DevOps

This repository contains CI/CD pipelines to build and test Intygstjänster.

## Local proxy

Install [Caddy](https://caddyserver.com/) and [mkcert](https://github.com/FiloSottile/mkcert) using for example scoop on windows

```shell
scoop install caddy mkcert
```

install the local certificate to be used by windows

```shell
$ mkcert -install
Created a new local CA 💥
The local CA is now installed in the system trust store! ⚡️
The local CA is now installed in the Firefox trust store (requires browser restart)! 🦊
```

Generate certificates with PowerShell script `generate-certs.ps1`. a bash and [Nushell](https://www.nushell.sh/) version of the script is included in the repo.

```shell
proxy/generate-certs.ps1
```

Launch caddy

```shell
caddy run --config Caddyfile
```

### Troubleshoot

PowerShell might need to be setup to allow user scripts, open PowerShell as **Administrator** and run:

```shell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
