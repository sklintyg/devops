# Use Caddy instead of nginx

Alternative to nginx for windows users is to use caddy

## Stop nginx process

Navigate to folder containing docker-compose.yaml and issue the following command to only stop nginx.

```bash
docker compose stop nginx
```

## Installation

Install caddy for with prefered [method](https://caddyserver.com/docs/install#install).

For example choco:

```bash
choco install caddy
```

Or scoop:

```bash
scoop install caddy
```

Or using curl:

```bash
curl.exe https://webi.ms/caddy | powershell
```

## Add locally signed certificate

install [mkcert](https://github.com/FiloSottile/mkcert) and run

```bash
mkcert -key-file key.pem -cert-file cert.pem *.localtest.me
```

## Run Caddy

Make sure the path to `caddy.exe` is avilable in your environment `PATH`

```bash
caddy run --config Caddyfile
```

## Run caddy as a service

Documentation for running Caddy as a service can be found on the [official website](https://caddyserver.com/docs/running#windows-service).
