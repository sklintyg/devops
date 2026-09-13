# Local development environment for Intygstjänster: analysis and idea catalogue

Status: proposal / idea catalogue, 2026-09-13. Nothing in this document is implemented yet. Each idea is meant to be tried in isolation and kept or dropped on its own merits.

This file is the source. `local-dev-environment-analysis.html` next to it is a self-contained rendering of the same text for reading in a browser (GitHub and Bitbucket show HTML files as source, not rendered, so read the Markdown there and open the HTML locally). Regenerate it with `doc/build-html.sh` after editing the Markdown.

## 1. Purpose and goals

The local development environment exists to support the work, not to constrain it. Concretely it should:

- let a developer (or a coding agent) run **any subset** of the system with one command, and work on **any one app** with the normal `gradlew appRun` / IntelliJ workflow, with a debugger attached;
- be **production-like**: real apps talking to each other over the real protocols, fake data only at the edges (intyg-proxy-service for PU/HSA, intyg-mock-service for recipients/NTjP), no stubs inside the apps;
- make switching between "which app am I working on" cheap and safe;
- work the same on Windows + WSL2 (Docker Desktop, Podman, or plain docker engine) and macOS Apple Silicon (Podman), without engine-specific knowledge leaking into config;
- coexist with the hjmtj family on the same laptop without port or hostname conflicts;
- be **agent-friendly**: discoverable, scriptable, non-interactive, machine-readable status, clear log locations;
- not be designed around today's laptops; hardware is the cheaper variable.

This document focuses on Intygstjänster. hjmtj has the same shape (Spring Boot apps + MySQL/Redis/nginx on `*.localtest.me`) and is simpler, so anything that works here transfers.

## 2. Current state

### 2.0 Where the repositories live

The application repositories are being migrated from GitHub (`github.com/sklintyg`) to Bitbucket (`bitbucket.drift.inera.se/scm/bksint`), one at a time. As of this writing the migrated repos are webcert, intygstjanst, certificate-service, certificate-print-service, certificate-analytics-service, customer-terminate-service, intyg-mock-service, intyg-proxy-service, intygsadmin, logsender, minaintyg, private-practitioner-service, rehabstod, sjut and statistik. Still on GitHub: devops (this repo), frontend, common, infra, intyg-bom, intyg-env, intyg-app, refdata, schemas. On a developer machine this typically means two checkout roots (here `~/k1/intygstjanster/` for Bitbucket and `~/k1/intyg/` for GitHub), and the facts below were taken from the Bitbucket copies where they exist. Anything that assumes "sibling checkouts" must accept a list of roots, not one (see ideas D, H and L).

### 2.1 The devops repository

- Two divergent trunks. `release/2021-2` (origin/HEAD) owns `develop/` and `scripts/` and has the newest commits (MySQL 8.4, websocket fix in nginx, mailpit). `main` owns the modernized `apps/` environment (parameterized image tags, `start`/`stop` scripts, config mounted from repo checkouts). Neither is an ancestor of the other.
- `feature/update-and-merge-branches` is an in-flight manual reconciliation of the two, already stale.
- `feature/caddy` replaces the nginx container with host-native Caddy + mkcert (Windows/scoop flavoured, portable idea).
- `feature/mac-with-podman` (this branch) is a three-file Podman/macOS fork of `develop/`: `host.containers.internal` upstreams, mailpit instead of mailhog, Corretto instead of Temurin for ActiveMQ.
- Three incompatible ways of reaching the host from a container coexist: `host.docker.internal` + `host.docker.external` (WSL, via `extra_hosts` and a parsed Windows IP), `host.containers.internal` (Podman), and "run the proxy on the host so no alias is needed" (Caddy). Three different Linux-only host-IP heuristics are in the tree.

### 2.2 Infrastructure compose (`develop/docker-compose`)

| Service | Image | Host ports | Notes |
|---|---|---|---|
| mysql | mysql:8.4.8 | 3306 | root/2lkopp; `init-db/init.sql` creates 12 databases with user = password |
| redis | redis:6.0.9-alpine | 6379 | password `redis` |
| activemq | built, Apache ActiveMQ 5.17.2 | 61616 jms, 5672, 61613, 61614, 1883, UI 8861→8161 | activemqUser/activemqPassword, admin/admin |
| mailpit | axllent/mailpit | 1025 smtp, 8025 UI | |
| nginx | nginx:latest | 80, 443 | wildcard `*.localtest.me`, self-signed cert + passphrase committed |

This is the `release/2021-2` state, which is the newest. `main` lags behind it in `develop/` (MySQL 8.0, no mailpit, no websocket headers in nginx).

Structural issues:

- No named volumes: `compose down` wipes MySQL, Redis and KahaDB. Persistence and "reset" are the same action.
- No compose project name. The directory is literally named `docker-compose`, and so are `apps/docker-compose` and hjmtj's, so all three stacks share the project name `docker-compose`.
- Fixed, unprefixed `container_name`s (`mysql`, `redis`, `nginx`, `amq`) prevent a second stack on the same machine.
- nginx routes `https://<x>.localtest.me` to `upstream <x>` and **refuses to start** if any upstream hostname cannot be resolved. The upstream list is stale: `pp` points at 8060 (private-practitioner-service is on 18070), and there is no entry for ips, cs, cps, cas, ims or mailpit.

### 2.3 Application compose (`apps/docker-compose`, one colleague's environment)

Runs published images `docker.drift.inera.se/intyg/<app>` with one compose profile per app. A `start wc it ips` script sets `COMPOSE_PROFILES` and, per app, a `<X>_HOST` variable that is either the container network host (app containerized) or the Windows host IP (app running in the IDE). This "any app can be either a container or a native process" switch is exactly the right idea; the implementation is Windows/WSL-only and hand-maintained. On `main`, per-app config is mounted from sibling checkouts under a hardcoded `/mnt/c/repos` tree. Only its author uses it.

### 2.4 Application conventions (the assets to build on)

- All apps are Spring Boot 4.1 on Java 25 / Gradle 9.6 (intyg-bom 1.0.0.16 or 1.0.0.18) except statistik, which is still a gretty war on Java 21 / Gradle 8.14 (intyg-bom 1.0.0.14). A developer who touches statistik or `infra` needs a second JDK; everyone else needs Java 25 only.
- Every app repeats a copy-pasted `appRun` / `appRunDebug` block; the JDWP port is a literal in each build file; `-Dinstance=N` works only in intygsadmin and statistik; webcert cannot be started with `java -jar` because `dev.http.port` is supplied only as gradle JVM args.
- **The config contract is uniform and container-symmetric.** Locally: `devops/dev/config/application-dev.*` loaded via `spring.config.additional-location` plus `-Dapplication.dir=<repo>/devops/dev`. In Kubernetes: the same files at `/opt/<app>/config` with `APPLICATION_DIR=/opt/<app>` and env-var overrides using Spring relaxed binding (`CERTIFICATESERVICE_BASE_URL`, `SPRING_ACTIVEMQ_BROKER_URL`). The base image honours `JAVA_OPTS`. Nothing new has to be invented to run an app image locally.
- App-to-app wiring in dev config is `http://localhost:<port>`. Browser-facing URLs are `https://<x>.localtest.me`, and those hostnames are registered with the Inera dev IdP, so SAML login depends on them.
- Libraries: `common` 4.4.0-SNAPSHOT is consumed by webcert and intygstjanst (Java 25); `infra` 4.1.0-SNAPSHOT by intygsadmin and statistik (infra itself builds on Java 21). Both are published locally with `./gradlew build install`. infra is being inlined into the apps and retired.
- Frontends live in the `frontend` pnpm monorepo (vite): webcert 3000, rehabstod 5173, minaintyg 5174. The committed `.env.development` points at the shared devtest backends; talking to local backends requires a gitignored `.env.development.local` that nobody can discover.
- Testcontainers integration tests are self-contained and do not use the compose infrastructure. They are unaffected by anything here.

### 2.5 Port map today

| App | http | internal | mgmt | debug |
|---|---|---|---|---|
| webcert | 8020 | 8120 | 8220 | 8820 |
| intygstjanst | 8080 (`/inera-certificate`) | 8180 | 8082 | 8880 |
| rehabstod | 8030 | – | 8031 | 8830 |
| minaintyg | 8041 | – | – | 8841 |
| statistik | 8050 | 8150 | – | 8850 |
| intygsadmin | 8070 | 8170 | 8170 | 8870 |
| logsender | 8010 | – | – | 8110 |
| sjut | 8090 | – | – | 8891 |
| customer-terminate-service | 18010 | – | – | 18011 |
| intyg-proxy-service | 18020 | – | – | 18021 |
| certificate-service | 18030 | – | – | 18031 |
| certificate-print-service | 18040 | – | – | 18041 |
| certificate-analytics-service | 18050 | – | – | 18051 |
| private-practitioner-service | 18070 | – | – | 18071 |
| intyg-mock-service | 18888 | – | – | 18889 |
| webcert-frontend (vite) | 3000 | | | |
| rehabstod-frontend (vite) | 5173 | | | |
| minaintyg-frontend (vite) | 5174 | | | |

Collisions and drift:

- vite 3000: webcert-frontend vs intygsadmin's own client.
- vite 5173: rehabstod-frontend vs intyg-mock-service's UI.
- 8861: ActiveMQ web UI sits in the 88XY debug band (the README assigns it to privatläkarportal instance 2).
- logsender debugs on 8110, which is the 81XY internal band; sjut debugs on 8891, the instance-1 slot.
- `develop/README.md` documents management ports as 81XY (webcert uses 8220), lists no 18xxx services, and describes `restAssured`, `protractorTest`, `cypressTest`, `fitnesseTest` gradle tasks that no longer exist.

### 2.6 hjmtj coexistence

hjmtj's compose (`hjmtj-devops/dev/docker-compose`) already uses a named network, named volumes and prefixed container names. Hard conflicts with intyg today:

| Resource | intyg | hjmtj |
|---|---|---|
| 80 / 443 | nginx, wildcard `*.localtest.me` | nginx, wildcard `*.localtest.me` |
| 3306 | mysql | hjmtj-mysql |
| 1025 / 8025 | mailpit | mailpit |
| compose project name | `docker-compose` | `docker-compose` |

Whichever nginx binds 443 first owns every `*.localtest.me` name on the laptop. App ports do not collide (hjmtj uses 190X0), nor do Redis (7000–7005 vs 6379) or ActiveMQ.

### 2.7 Agent enablement

The `.ai-resources` submodule distributes skills and instructions into every app repo (`CLAUDE.md` is `See @AGENTS.md`). Only certificate-service and intyg-mock-service have an AGENTS.md, and both document build and test commands only. No document anywhere ties the gradle commands to the compose infrastructure, the hostnames or the port map. The devops repo has neither AGENTS.md nor `.ai-resources`. There is no Makefile, justfile, Taskfile or `.mcp.json` in any repo.

## 3. The target run model

### 3.1 In plain terms

- **The app you work on runs exactly as today.** Open a terminal in the repo and run `./gradlew appRun` or `appRunDebug`, or press Run/Debug in IntelliJ. Nothing in the app's dev config changes.
- **Everything else runs as containers**, from published images or images built from a local checkout, started with one command. Infrastructure (MySQL, Redis, ActiveMQ, mailpit, proxy) is always containers.
- **Any mix is allowed**, per app, and switchable at any time. Two apps native in two terminals and the rest containers is the normal case.
- **Every app has two stable addresses**, and that is what makes the mix painless:
  - from the laptop (a native app, the browser, curl, IntelliJ): `localhost:<port>`, whether the app is a container or a gradle process, because containers publish the app's own port number;
  - from inside the compose network: `<service>:<port>`, e.g. `intyg-proxy-service:18020`. When that app is running natively, a tiny forwarder container holds the service name and forwards to the laptop.
- Consequence: no app config changes when an app switches mode, and no `host.docker.internal` / `host.containers.internal` logic exists anywhere except inside the forwarder definition.
- `intyg up` never starts gradle. Humans start native apps themselves. `intyg run <app> [--debug]` exists for agents and convenience: it starts the gradle process detached with a log file and a PID file.

### 3.2 Picture

```
 browser ── https://wc.localtest.me ──▶ nginx (:80/:443, container)
                                          │  proxy_pass http://webcert-frontend:8080   (service name, resolved per request)
 ── compose network "intyg" ──────────────┼──────────────────────────────────────────────────────────────────────
   [webcert-frontend]   [webcert]   [certificate-service]   [intygstjanst]   [ips] [ims] [cps]   [mysql] [redis] [activemq]
     image               image        forwarder ──▶ dev-host:18030            image ...           always containers
                                       (alias: certificate-service)
 ── laptop ───────────────────────────────┼──────────────────────────────────────────────────────────────────────
                                          ▼
   terminal:  cd certificate-service && ./gradlew appRunDebug      (listens on localhost:18030, debug 18031)
              talks to localhost:8180 (intygstjanst container, published port), localhost:3306, localhost:61616 ...
```

Read it from three positions:

- The **browser** only ever sees `https://<x>.localtest.me`; nginx finds the app by service name.
- A **container** (webcert here) calls `certificate-service:18030`; today that name is a forwarder to the laptop, tomorrow it is the real container. webcert's env does not change.
- The **native app** (certificate-service here) calls `localhost:8180`, `localhost:3306` and so on, exactly as its `application-dev.yml` already says.

## 4. Scenarios

Commands use the proposed `intyg` CLI (idea G). Short names: wc, it, cs, cps, ips, ims, mi, rs, st, ia, ls, pps, sjut, cas, cts, plus `wc-fe`, `mi-fe`, `rs-fe` for the frontends.

### 4.1 Start the day on the webcert backend

```
intyg up intygstjanster --native wc
cd ../webcert && ./gradlew appRunDebug        # or IntelliJ Run/Debug, as today
```

Infrastructure plus ips, ims, cs, cps, it and webcert-frontend come up as containers. wc gets a forwarder. `https://wc.localtest.me` and fake login work, the debugger is on 8820. Total setup: one command and the same gradle command as today.

### 4.2 Switch to intyg-proxy-service after working on webcert and certificate-service

```
intyg native ips                 # replaces the ips container with a forwarder
intyg container wc cs            # brings wc and cs back as containers from the registry
cd ../intyg-proxy-service && ./gradlew appRunDebug
```

If the webcert changes are uncommitted and still needed, either leave the webcert gradle process running in its terminal (nothing forces a switch), or `intyg up wc --build` to build an image from the local checkout. The containerized webcert now calls `intyg-proxy-service:18020`, which forwards to the gradle process.

### 4.3 Reproduce a bug reported on a specific release

```
intyg up full wc:1.23.0.4 cs:2.1.0.1
intyg reset db
intyg logs wc -f
```

Everything containerized at exact versions, clean data, recreate the state through fake login and the testability APIs. To fix it: `intyg native wc` and debug from the IDE. Alternatively attach the IDE's Remote JVM Debug to the *container* on 8820, since every container exposes JDWP on the app's known debug port; this needs a checkout matching the image version.

### 4.4 Debug current work in one app

`./gradlew appRunDebug` or IntelliJ Debug on the gradle task. Unchanged from today. The difference is that the other five apps are one `intyg up` away instead of five terminals.

### 4.5 Frontend work

```
intyg up intygstjanster --native wc-fe
cd ../frontend && pnpm --filter @frontend/webcert dev:local
```

nginx sends `wc.localtest.me` to the forwarder, which sends it to vite on 3000. HMR works through TLS with `VITE_WS_PROTOCOL=wss`. The webcert backend is a container unless also marked native.

### 4.6 Test sending to a recipient or status messages to an EHR system

intyg-mock-service is part of every preset as a container and reachable at `https://ims.localtest.me` (its inspection UI and Swagger). No stub profiles in the apps.

### 4.7 A coding agent works on certificate-service

From the repo's AGENTS.md:

```
../devops/intyg up cs --native cs      # starts only what cs depends on (ips, cps, infra)
../devops/intyg run cs --debug         # gradle appRun detached, log in ~/.intyg-dev/run/cs.log
../devops/intyg wait --for cs
curl http://localhost:18030/actuator/health
../devops/intyg logs cs --grep 'ERROR|FAILED'
../devops/intyg stop cs
```

Never a foreground gradle process, machine-readable status, known log paths.

### 4.8 Fresh laptop or a tester

```
intyg doctor
intyg certs
intyg up intygstjanster
```

A full running system with no JDK and no checkouts. JDKs and checkouts are added only for the apps that will be changed.

### 4.9 Switching between intyg and hjmtj

Today: `intyg down` then start hjmtj, or vice versa. After the shared edge project (idea F): both at once.

### 4.10 What this model does not do

- Run the same app as both container and native at the same time on the same port. A second native instance uses `-Dinstance=1` (idea I).
- Hot reload of Java code inside containers. Native mode is for code you are changing.
- Native-speed containers on Apple Silicon until `springboot-base` is multi-arch; until then they run under emulation.
- Automatic reach-back to the IDE when the IDE runs on Windows and the container engine in WSL: this needs WSL mirrored networking or one `DEV_HOST_IP` variable (idea B).
- Meaningful breakpoints in a container whose image does not match the checkout.

## 5. Ideas

Each idea: problem, proposal, trade-offs, smallest experiment, things to verify. Ordered roughly by the migration path in section 6.

### A. One compose project, hygiene first (no behaviour change)

Problem: two divergent branches, no project name, no volumes, fixed container names, a wiped database on every `down`.

Proposal:

- Declare `main` the trunk for `develop/` and `apps/`. Land `feature/update-and-merge-branches`, cherry-pick the Podman fixes from `feature/mac-with-podman`, delete the dead branches.
- Add the top-level `name: intyg` key. Move `develop/docker-compose/` to `develop/infra/` so the directory name stops leaking into the project name.
- Remove every `container_name`; service names are the DNS names anyway.
- Named volumes `intyg_mysql` and `intyg_activemq` (KahaDB, so queued messages survive a restart). Redis stays ephemeral.
- `healthcheck` on mysql, redis and activemq, and `depends_on: condition: service_healthy` from the apps, so `intyg up` works from cold without retries.
- Bind every host publish to `127.0.0.1`. Move the ActiveMQ UI from 8861 to 8161. Stop publishing 5672/61613/61614/1883 unless someone uses them.
- Stop committing the TLS key and passphrase (see idea C).

Trade-offs: none for users. `docker compose down -v` becomes the explicit "wipe" gesture.

Smallest experiment: the compose hygiene is one PR against `develop/` with no effect on how anyone works today.

### B. Stable names on both sides

Problem: containers must reach native apps and vice versa; today that is solved with engine-specific host aliases and parsed IP addresses.

Proposal:

- Native apps keep today's `localhost:<port>` wiring, untouched.
- Containerized apps get **constant** env in their compose fragment: `CERTIFICATESERVICE_BASE_URL=http://certificate-service:18030`, `DATABASE_SERVER=mysql`, `SPRING_ACTIVEMQ_BROKER_URL=tcp://activemq:61616`. No `<X>_HOST` variables.
- **Forwarder services.** For every app, a profile `<app>-native` runs a tiny TCP forwarder (socat or equivalent) with network alias `<app>`, forwarding each of the app's ports to `dev-host:<port>`:

  ```yaml
  certificate-service:
    profiles: [cs]
    image: ${CS_IMAGE:-docker.drift.inera.se/intyg/certificate-service}:${CS_VERSION:-latest}
    ports: ["127.0.0.1:18030:18030", "127.0.0.1:18031:5005"]
  certificate-service-native:
    profiles: [cs-native]
    image: alpine/socat
    command: TCP-LISTEN:18030,fork,reuseaddr TCP:dev-host:18030
    networks: { default: { aliases: [certificate-service] } }
    extra_hosts: ["dev-host:${DEV_HOST_IP:-host-gateway}"]
  ```

  The CLI computes `COMPOSE_PROFILES`: `<x>` for container mode, `<x>-native` otherwise. An app not mentioned at all gets a forwarder, so a forgotten dependency fails with "connection refused" rather than a DNS error.
- Exactly one host alias, `dev-host`, mapped to `host-gateway`, used only by forwarders. `DEV_HOST_IP` overrides it for the "IDE on Windows, engine in WSL" case (or enable WSL mirrored networking, which makes it unnecessary).

Trade-offs: one more (tiny) container per native app; apps with several ports (webcert 8020 + 8120, intygstjanst 8080 + 8180, intygsadmin 8070 + 8170) need a forwarder that listens on several ports, which socat does not do in one process (small entrypoint script, or a multi-port image). The benefit is that every piece of app config becomes static and identical on every engine.

Fallback: keep the `<X>_HOST` switch from `apps/` but let the CLI compute it using `host-gateway`. Less elegant, same portability.

Smallest experiment: run cs as a container and ips natively with a socat forwarder, and check that cs reaches ips through the alias on both Podman (macOS) and Docker Desktop (WSL).

Verify: Podman 5 maps the literal `host-gateway` in `extra_hosts` (believed since 5.0; confirm on 5.8 with `podman run --rm --add-host=x:host-gateway alpine getent hosts x`); a socat image is reachable through Inera's registry proxy; on a Linux engine, `host-gateway` is the bridge IP, so native apps must listen on all interfaces, not only loopback (Spring Boot's default is all interfaces).

### C. Reverse proxy: keep nginx, change what it points at

Problem: nginx upstreams point at engine-specific host aliases, the list is stale, and nginx refuses to start when a name does not resolve.

Proposal: the proxy software is not the important decision. Two properties are:

1. Upstreams are compose **service names** (`webcert-frontend:8080`, `certificate-service:18030`), never host aliases, so the proxy stops caring where apps run (idea B makes the names always resolvable).
2. Upstreams are resolved **per request** so that a missing app gives 502 on that host only.

nginx does both:

```nginx
resolver 127.0.0.11 valid=5s;
map $subdomain $upstream_port {
    wc   8080;    # webcert-frontend
    it   8080;
    cs   18030;
    ...
}
map $subdomain $upstream_service { wc webcert-frontend; it intygstjanst; cs certificate-service; ... }
server {
    listen 443 ssl;
    server_name ~^(?<subdomain>.+)\.localtest\.me$;
    location / { proxy_pass http://$upstream_service:$upstream_port; ... }
}
```

Generated from the manifest (idea H) with the complete host list: wc, it, rs, mi, st, ia, ls, sjut, cts, pps (fixes the stale `pp`), ips, cs, cps, cas, ims, amq, mail. Keep the existing websocket headers.

TLS: an `intyg certs` command generates a wildcard `*.localtest.me` certificate with mkcert into a gitignored directory (reuse the scripts from `feature/caddy`). No keys or passphrases in git. Hostnames stay as they are, since they are registered SP URLs at the Inera dev IdP.

Why nginx by default: the team knows it, production frontends ship on nginx, hjmtj uses nginx. **Caddy as an optional experiment**: same result in three lines per host, HTTP/2 and websockets without configuration, a built-in local CA as fallback when mkcert is absent. If tried, run it containerized (host-native Caddy from `feature/caddy` cannot use service names and needs a Windows service). Traefik is not recommended: it needs the engine socket inside a container, which is awkward with Podman machines.

Smallest experiment: replace the current `default.conf` with the resolver + map version, keeping upstreams as `dev-host:<port>` at first. Behaves exactly like today, with one alias instead of three and no startup failure on missing apps.

### D. Local images from the existing Dockerfiles

Problem: `apps/` can only run what Jenkins has published. Working on two apps at once, or testing an unpublished change from a colleague's branch, means running everything natively.

Proposal: `intyg build <app>` runs `./gradlew build -x test` in the sibling checkout and then `compose build`, using both `build:` and `image:` on the service:

```yaml
webcert:
  image: ${WC_IMAGE:-docker.drift.inera.se/intyg/webcert}:${WC_VERSION:-latest}
  build:
    context: ${INTYG_REPOS:-../..}/webcert
    args: { from_image: "${SPRINGBOOT_BASE_IMAGE}" }
  pull_policy: ${PULL_POLICY:-missing}
```

Locally built images are tagged `localhost/intyg/<app>:local`. This produces the same image Jenkins ships; no jib, no buildpacks (buildpacks would give a different image, need the engine socket from Gradle, and do not cover the statistik war).

Config for containerized apps is mounted from `<checkout>/<app>/devops/dev` into `/opt/app` (the Kubernetes layout, as `apps/` on `main` already does), replacing the hardcoded `/mnt/c/repos`. `INTYG_REPOS` is a list of roots (for example `~/k1/intygstjanster:~/k1/intyg`), searched in order, because of the GitHub-to-Bitbucket migration; the CLI resolves each app's checkout once and writes the result to the compose env file, so the compose file itself only sees one path per app. For apps without a checkout, the CLI does a sparse clone of just `devops/dev` (from Bitbucket or GitHub, whichever the manifest names) into `~/.intyg-dev/config/<app>`.

Ask ops for: a multi-arch `springboot-base` (arm64 for Apple Silicon; Chrome in certificate-print-service under emulation is painful) and a documented `from_image` reference to default in `.env`.

Verify: Docker runs a `localhost/...` tag without trying to pull (Podman prefixes unqualified names with `localhost/` itself).

### E. Uniform remote debugging

Problem: debugging is available only for native apps, and the port is a literal in each build file.

Proposal:

- Every app container gets `JAVA_TOOL_OPTIONS=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005` (honoured by the JVM itself, so it also works for the Chrome-bearing print service and the statistik war) and publishes `127.0.0.1:<the app's existing debug port>:5005`.
- Result: the IntelliJ "Remote JVM Debug" configuration for webcert is port 8820 whether webcert is a container or was started with `appRunDebug`. Commit a generated `.run/<app>-remote-debug.xml` in each repo.
- Memory and JIT flags go in `JAVA_OPTS`, kept separate from the debug agent.

### F. Port and naming scheme

Rule: 80XY app → 81XY internal, 82XY management, 88XY debug; 18XY0 app → 18XY1 debug; 51XX vite dev servers; infrastructure keeps upstream defaults; everything bound to 127.0.0.1.

Fixes, one small PR per repo:

| Change | From | To |
|---|---|---|
| intygsadmin vite client | 3000 | 5176 |
| intyg-mock-service UI | 5173 | 5177 |
| logsender debug | 8110 | 8810 |
| sjut debug | 8891 | 8890 |
| ActiveMQ web UI | 8861 | 8161 |
| proxy entry `pp` | 8060 | `pps` → 18070 |

hjmtj coexistence:

- Project names `intyg`, `hjmtj`, `edge`. `docker compose ls` then shows three rows, which is what an agent needs to reason about.
- A shared **`edge`** compose project containing one nginx (80/443) and one mailpit, with an external network `edge`. Each family attaches its web-facing services (or forwarders) to that network and drops a `conf.d/<family>.conf` with its hosts. Subdomains are disjoint (`wc, rs, mi, ...` vs `hjmtj, minio, kibana, ...`), so one proxy serves both. Because upstreams resolve per request, an absent family gives 502 on its hosts and nothing else.
- MySQL: both families hardcode 3306 in dev config, so one must move. Proposal: hjmtj to 3316 (fewer consumers, their decision). Alternative: no host publish and a `DATABASE_PORT` variable for native apps, more invasive.
- Until the edge project exists, `intyg doctor` detects who holds 80/443/3306 and prints what to stop.

### G. Single CLI entry point

Problem: today's knowledge is spread over a README, three shell scripts and people's heads; agents have no non-interactive entry point.

Proposal: `devops/intyg` (bash launcher) and `devops/intyg.ps1`, runnable from any sibling repo as `../devops/intyg`.

| Verb | Meaning |
|---|---|
| `up <preset\|apps...> [app:version] [--native x] [--build x]` | start; `up <app>` alone starts that app's dependencies from the manifest |
| `native <app...>` / `container <app...>` | switch mode of a running stack |
| `run <app> [--debug]` / `stop <app>` | start/stop a native app detached (log + PID under `~/.intyg-dev/run/`) |
| `down [--volumes]` | project-scoped, never touches hjmtj |
| `status [--json]` | per app: mode, state, health, ports, URL, log path |
| `logs <app> [-f] [--since] [--grep]` | container or native log, same verb |
| `wait --for a,b [--timeout]` | health wait |
| `reset [db\|mq\|all] [--yes]` | data only, keeps images; `db snapshot/restore <name>` via mysqldump |
| `url <app>`, `env [--shell\|--json]` | URLs, ports, `VITE_API_TARGET` etc. for scripts and agents |
| `doctor [--fix]` | see idea L |
| `certs` | mkcert wildcard cert |
| `gen <proxy\|readme\|agents\|intellij\|frontend-env> [--check]` | see idea H |

Presets: `intygstjanster` = ips, ims, cs, cps, it, wc, wc-fe; `minaintyg` = intygstjanster + mi, mi-fe; `rehabstod` = ips, ims, it, rs, rs-fe; `full` = everything. Stable exit codes (0 healthy, 2 unhealthy, 3 config error).

Language: start in bash for `up/down/logs/certs/status` (a day's work; runs in WSL, Git Bash and macOS). Graduate to TypeScript bundled with esbuild into one committed file, launched by the same wrapper, once `status --json`, `wait`, `doctor` and detached process management arrive; node is already required for the frontends and the team writes TypeScript. Not Python (absent in Git Bash, no YAML in the standard library), not Go (needs a release pipeline), not Gradle (startup time, two Gradle lines in play). Compose carries the topology, so the wrapper stays thin.

Make it family-parameterized (`family: intyg | hjmtj`) so hjmtj reuses it unchanged.

### H. A manifest as single source of truth

Problem: ports and hostnames live in the compose file, the nginx config, the README, each app's build file, each frontend's env file, and drift between them is already visible.

Proposal: `develop/intyg-env.yaml`:

```yaml
version: 1
domain: localtest.me
project: intyg
infra: { mysql: 3306, redis: 6379, activemq: [61616, 8161], mailpit: [1025, 8025], proxy: [80, 443] }
presets:
  intygstjanster: [ips, ims, cs, cps, it, wc, wc-fe]
  minaintyg:      [+intygstjanster, mi, mi-fe]
  rehabstod:      [ips, ims, it, rs, rs-fe]
  full:           [+minaintyg, +rehabstod, st, ia, ls, pps, sjut, cas, cts]
apps:
  wc:
    name: webcert
    kind: spring-boot              # spring-boot | vite | static
    repo: webcert                  # directory name under one of the INTYG_REPOS roots
    git: https://bitbucket.drift.inera.se/scm/bksint/webcert.git   # for sparse clones; moves as repos migrate
    image: docker.drift.inera.se/intyg/webcert
    java: 25
    ports: { http: 8020, internal: 8120, mgmt: 8220, debug: 8820 }
    host: wc                       # wc.localtest.me
    route: wc-fe                   # what the proxy targets for this host
    health: /actuator/health
    profiles: dev,testability-api,caching-enabled,ia-stub,certificate-analytics-service-active
    depends: [it, cs, cps, ips, ims]
    mode: native                   # default when not specified
    maven_local: [common]
    fake_login: /welcome.html
  wc-fe:
    kind: vite
    repo: frontend/apps/webcert
    image: docker.drift.inera.se/intyg/webcert-frontend
    ports: { http: 3000 }
    env: { VITE_API_TARGET: "http://localhost:${wc.ports.http}", VITE_HOST: wc.localtest.me }
```

Generate from it: the proxy config, the README port/URL tables (between marker comments), the AGENTS.md dev-env snippet, IntelliJ run configurations, the frontend `.env.localdev` files. Validate (not generate) the compose fragments in a first phase: ports, profiles and images must match. `intyg gen --check` in the devops CI fails on drift.

Why not make compose the source of truth: `docker compose config` cannot express native mode, JDK version, maven-local prerequisites, health URLs, repo paths or dependency order for native starts.

### I. A native-run convention in the app repos

Problem: fourteen copies of the same gradle block, hardcoded debug ports, `-Dinstance` in two apps only.

Proposal: a small Gradle plugin `se.inera.intyg.dev-run` published from the `intyg-bom` repo next to `platform`, `catalog` and `bom.properties`, and a per-repo `devops/dev/dev.properties`:

```
app=webcert
port.http=8020
port.internal=8120
port.mgmt=8220
port.debug=8820
profiles=dev,testability-api,caching-enabled,ia-stub
```

The plugin keeps `appRun`, adds `-Pdebug` and `-PdebugSuspend`, applies `-Dinstance=N` to every port, honours env overrides (`INTYG_PORT_HTTP`, `INTYG_PROFILES`, ...) so CLI-driven runs cannot drift from the manifest, and offers `devInfo --json`. `appRunDebug` stays as an alias. The plugin does not detach processes; that is the CLI's job.

Migrate the smallest repos first (certificate-service, intyg-proxy-service), webcert last since it needs the `dev.http.port` → `server.port` cleanup that would also let it start with `java -jar`.

Verify: whether Nexus serves as a Gradle plugin repository for `pluginManagement`, or the plugin must be resolved through `buildscript` dependencies.

### J. Frontends talk to local backends by default

Problem: local work needs a gitignored `.env.development.local` that is not documented anywhere.

Proposal: commit `.env.localdev` per app (`VITE_API_TARGET=http://localhost:8020`, `VITE_HOST=wc.localtest.me`, `VITE_WS_PROTOCOL=wss`) and add `"dev:local": "vite --mode localdev"`. `intyg run wc-fe` uses it, and `intyg env --shell` exports the same variables for plain `pnpm dev`. Keep `.env.development` pointing at devtest; frontend work without backends is a legitimate mode.

Check: minaintyg's `VITE_HOST=mi2.mi.localtest.me` versus the proxy's `mi` host.

### K. Agent enablement, without an MCP server

Proposal: the CLI with `--json`, plus a shared instructions file and a `/dev-env` skill distributed through ai-resources (`knowledge/instructions/dev-env.md`, `knowledge/skills/dev-env/`). Each app's AGENTS.md gets one include line and a two-line repo-specific block: "this app is `wc`; minimal dependencies: `intyg up wc --native wc`".

`devops/AGENTS.md` outline:

1. What this repo is, where the manifest is, "edit the manifest, then `intyg gen`; CI checks drift".
2. Topology table (generated): short name, hostname, ports, health URL, depends-on, default mode.
3. Presets and the commands in idea G.
4. Runtime rules: never run `gradlew appRun`, `bootRun` or `pnpm dev` in the foreground; use `intyg run` and `intyg wait`; run `intyg status --json` before assuming anything is up; never `docker compose down` outside the project.
5. Logs: `intyg logs <app>` for containers; `~/.intyg-dev/run/<app>.log` for native apps; Spring startup failures contain `APPLICATION FAILED TO START`.
6. Calling APIs: through the proxy (`curl -k https://wc.localtest.me/...`), directly (`http://localhost:8020`), the `http/*.http` files in each repo, fake login URLs, testability endpoints, where test users come from.
7. Data: what `reset` clears, credentials for MySQL/Redis/ActiveMQ.
8. Prerequisites: `common`/`infra` install, Java 25 (Java 21 only for statistik/`infra`), `intyg doctor`.

Hooks: an opt-in `SessionStart` hook that prints `intyg status --brief` (three-second timeout, silent on failure); optionally a `PreToolUse` warning on foreground `appRun` / `bootRun` / `pnpm dev`. Add `.ai-resources` and an AGENTS.md to the devops repo itself.

An MCP server would duplicate every CLI verb behind a running process and a `.mcp.json` per repo. Revisit only for things a CLI does badly.

### L. `doctor` checks

| Check | Fix printed |
|---|---|
| engine reachable, compose ≥ 2.20 (`include`), which provider (`docker compose`, `podman compose` → docker-compose or podman-compose) | install/start hints |
| `host-gateway` resolves inside a throwaway container | engine version hint |
| 80/443/3306/6379/61616 and every requested app port free; who holds it (hjmtj, stale native PID, other) | `intyg down`, `docker compose -p hjmtj down`, `kill <pid>` |
| `*.localtest.me` resolves to 127.0.0.1 (some corporate DNS blocks it) | hosts-file entries |
| mkcert installed, CA trusted, cert present | `mkcert -install && intyg certs` |
| JDK 25 available, plus JDK 21 when statistik or `infra` is in the requested set (or Gradle toolchain auto-provisioning enabled) | sdkman/winget commands |
| `~/.m2` has `common` / `infra` snapshots, not older than the repo HEAD | `(cd ../common && ./gradlew install)` |
| checkouts present for native apps in the preset, searching every `INTYG_REPOS` root (Bitbucket and GitHub copies) | clone hints with the current remote for that repo |
| node ≥ 20, pnpm, registry login (`docker.drift.inera.se`) | install hints |
| stale PID files | `--fix` removes them |
| `dev.properties` matches the manifest | shows the diff |
| WSL: repo on the Linux filesystem, Docker Desktop WSL integration enabled, VM memory (`.wslconfig`, `podman machine set --memory`) | hints |

### M. Resource budget

Per-service memory limits taken from the devtest Helm values:

| Service | Limit |
|---|---|
| webcert | 2 GiB |
| intygstjanst | 1.5 GiB |
| certificate-service, minaintyg, rehabstod, intygsadmin, statistik | 1 GiB each |
| certificate-print-service (JVM + Chrome) | 2 GiB |
| intyg-proxy-service, intyg-mock-service, pps, cas, cts, logsender, sjut | 512 MiB each |
| mysql (with 256 MiB buffer pool) | 1 GiB |
| activemq | 512 MiB |
| frontends, forwarders, nginx, mailpit, redis | 32–64 MiB each |

The `intygstjanster` preset fully containerized is roughly 9–10 GiB; everything containerized roughly 14–16 GiB. Realistic on a 32 GB laptop with the VM sized accordingly (this Mac's podman machine is 14.9 GiB / 8 CPU; 20–24 GiB is the first thing to change).

JVM flags for dev containers, in one `x-java-opts` anchor: `-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError -XX:TieredStopAtLevel=1 -Xss512k -Dspring.jmx.enabled=false`. C1-only noticeably cuts startup CPU and is fine for dev; drop it for performance work.

### N. Reduce prerequisites

- Publish `common` SNAPSHOTs to Nexus from CI, so only people changing `common` have to build it locally.
- Finish retiring `infra` (only intygsadmin and statistik still consume it).
- Gradle toolchain auto-provisioning (foojay resolver) in each repo's `settings.gradle`, so the right JDK downloads itself.
- Move statistik to intyg-bom 1.0.0.18 (Java 25) when its gretty/war setup allows, which removes the last second-JDK requirement for app developers.
- Later: Telepresence against devtest (the chart exists in `intyg-env/telepresence-oss`) as a complementary "one app locally against the cluster" mode.

## 6. Migration path

Each step is independently valuable and small enough for one PR.

1. Branch consolidation: `main` as the trunk for `develop/` and `apps/` (A).
2. Infrastructure compose hygiene: project name, no container names, volumes, healthchecks, 127.0.0.1 binds, AMQ UI port (A).
3. nginx config with `resolver` + port map and the complete host list, upstreams `dev-host:<port>` at first (C). Same behaviour as today on every engine, one alias instead of three, no startup failure on missing apps.
4. Bash `intyg` CLI MVP: `up`, `down`, `status`, `logs`, `certs` (G).
5. Merge `apps/` into the same project as profiles with constant env, forwarders, proxy upstreams switched to service names, JDWP on 5005 in every container (B, E). This is the step where "mix and match" starts working identically on all engines.
6. `intyg build`, IntelliJ run configurations (D, E).
7. Port cleanup PRs in the app repos, frontend `.env.localdev` (F, J).
8. Manifest, `intyg gen`, CI drift check, AGENTS.md and the ai-resources skill (H, K).
9. Gradle `dev-run` plugin (I); shared `edge` project with hjmtj (F).

## 7. Open questions and things to verify

- Podman ≥ 5: does the literal `host-gateway` in `extra_hosts` resolve through `podman compose` on macOS (libkrun/applehv) and on the Windows Podman machine?
- `podman compose` provider on Windows: docker-compose v2 delegation vs podman-compose; support for `name:`, `include`, `depends_on: condition: service_healthy`.
- Does WSL2 mirrored networking remove the need for `DEV_HOST_IP` when the IDE runs on Windows and the engine in WSL?
- Docker runs a `localhost/intyg/<app>:local` tag without attempting a pull?
- Is a socat image (or equivalent) available through Inera's registry proxy, or should the devops repo build a 5 MB forwarder image?
- amd64 emulation of `springboot-base` images on Apple Silicon: acceptable for everything except the print service?
- Does Nexus serve as a Gradle plugin repository?
- Which repos actually have the `SessionStart` ai-resources hook, and does the sync target `.claude/` as well as `.github/`?
- Which repos migrate to Bitbucket next (frontend, common, intyg-bom?), so the manifest's `git:` entries and the sparse-clone logic stay correct.
- How much of webcert's config references `${dev.http.port}` (scope of the `server.port` cleanup)?
- hjmtj team: MySQL on 3316, and joining a shared `edge` project?

## 8. Appendix

### 8.1 Compose fragment shape per app

```yaml
x-app: &app
  restart: on-failure
  pull_policy: ${PULL_POLICY:-missing}
  environment: &app-env
    APPLICATION_DIR: /opt/app
    SPRING_CONFIG_ADDITIONAL_LOCATION: file:/opt/app/config/
    JAVA_TOOL_OPTIONS: -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005
    JAVA_OPTS: -XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError -XX:TieredStopAtLevel=1
    DATABASE_SERVER: mysql
    REDIS_HOST: redis
    SPRING_ACTIVEMQ_BROKER_URL: tcp://activemq:61616

services:
  certificate-service:
    <<: *app
    profiles: [cs]
    image: ${CS_IMAGE:-docker.drift.inera.se/intyg/certificate-service}:${CS_VERSION:-latest}
    build: { context: "${INTYG_REPOS:-../..}/certificate-service", args: { from_image: "${SPRINGBOOT_BASE_IMAGE}" } }
    environment:
      <<: *app-env
      INTEGRATION_CERTIFICATEPRINTSERVICE_ADDRESS: http://certificate-print-service:18040
      INTEGRATION_INTYGPROXYSERVICE_ADDRESS: http://intyg-proxy-service:18020
    volumes: ["${INTYG_REPOS:-../..}/certificate-service/devops/dev:/opt/app:ro"]
    ports: ["127.0.0.1:18030:18030", "127.0.0.1:18031:5005"]
    mem_limit: 1g
    depends_on: { mysql: { condition: service_healthy }, activemq: { condition: service_healthy } }
  certificate-service-native:
    profiles: [cs-native]
    image: alpine/socat
    command: TCP-LISTEN:18030,fork,reuseaddr TCP:dev-host:18030
    networks: { default: { aliases: [certificate-service] } }
    extra_hosts: ["dev-host:${DEV_HOST_IP:-host-gateway}"]
```

### 8.2 What changes for a developer, in one table

| Today | Target |
|---|---|
| `docker-compose up -d` in `develop/docker-compose` | `intyg up <preset>` |
| one terminal + gradle build per app you need running | containers for everything you are not changing |
| `gradlew appRunDebug` for the app you work on | unchanged |
| `./start wc it ips` in `apps/`, WSL-only host IP detection | `intyg native x` / `intyg container y`, any OS |
| self-signed cert warning in the browser | mkcert-trusted wildcard cert |
| `docker-compose down` wipes data | `intyg reset db`, snapshots |
| README port table, partly wrong | generated from the manifest, CI-checked |
| nothing an agent can read | AGENTS.md + `intyg status --json` |

### 8.3 Related material in the repo

- `develop/README.md`: current handbook (keep the prose on modes and use-cases, drop the grunt/protractor/cypress sections, generate the tables).
- `apps/docker-compose/` on `main`: profiles, env-file layout, `start`/`stop` scripts (the `<X>_HOST` logic to be removed).
- `feature/caddy`: host list and mkcert scripts (`proxy/generate-certs.*`) to reuse for `intyg certs`.
- `develop/docs/docker-compose.drawio`: the existing diagram, to be updated to the picture in section 3.2.
