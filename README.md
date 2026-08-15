# makbot

A minimal Telegram bot CLI built with [Cobra](https://github.com/spf13/cobra) and
[telebot.v4](https://github.com/tucnak/telebot). Currently responds to a simple
`hello` message; the CLI is structured so more commands can be added easily.

`@ma_kbot_bot`

## Features

- Cobra-based CLI (`kbot`/`start`, `version`)
- Telegram long-polling bot via `telebot.v4`
- Responds to `hello` with a greeting (anything else gets `???`)
- Version command that prints the build version (git tag + short commit hash)
- Multi-OS / multi-arch builds (linux, darwin, windows; amd64, arm64)
- Multi-stage Docker build producing a minimal `scratch`-based image

## Prerequisites

- Go 1.22+ (Docker build uses `golang:1.26`)
- Docker (optional, for containerized builds)
- A Telegram Bot Token, set as the `TELE_TOKEN` environment variable
- Go modules (fetched automatically via `make fetch-deps` / `go mod download`):
  - `github.com/spf13/cobra`
  - `gopkg.in/telebot.v4`

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/mananievXAU/makbot.git
   cd makbot
   ```

2. Set your Telegram Bot Token:
   ```bash
   export TELE_TOKEN="your_telegram_bot_token"
   ```

3. Build for your platform (see [Makefile targets](#makefile-targets)), e.g.:
   ```bash
   make macos
   ```

4. Run the bot:
   ```bash
   ./makbot-darwin-arm64 start
   ```

## Usage

```
kbot [command]

Available Commands:
  start, kbot   Start the Telegram bot (long-polling)
  version       Print the build version
  help          Help about any command
```

Once running, message the bot:

- `hello` → bot replies `Hi!`
- anything else → bot replies `???`

## Makefile Targets

The `Makefile` drives formatting, testing, native builds, and Docker
image build/push/release for each supported OS/arch combination.

### Build & test

| Target | Description |
|---|---|
| `make format` | Run `gofmt -s -w` on the whole tree |
| `make fetch-deps` | Run `go get` to fetch dependencies |
| `make test` | Run `go test -v` |

### Native binaries

Each of these runs `fetch-deps`, `format`, and `test` first, then cross-compiles
a `CGO_ENABLED=0` binary with the version baked in via `-ldflags`:

| Target | Output |
|---|---|
| `make linux` | `makbot-linux-amd64` |
| `make macos` | `makbot-darwin-arm64` |
| `make windows` | `makbot-windows-amd64.exe` |

### Docker images

`make image` builds the image described in [Docker](#docker) using
`TARGETOS`/`TARGETARCH` build args. Convenience wrappers pin those args for you:

| Target | TARGETOS | TARGETARCH |
|---|---|---|
| `make image-linux` | linux | amd64 |
| `make image-arm` | linux | arm64 |
| `make image-macos` | darwin | arm64 |
| `make image-windows` | windows | amd64 |

Images are tagged as:
```
${REGISTRY}/${APP}:${VERSION}-${TARGETOS}-${TARGETARCH}
```
where `APP` is derived from the git remote name, `REGISTRY` defaults to
`nananiev`, and `VERSION` is `<latest git tag>-<short commit hash>`.

### Push & release

| Target | Description |
|---|---|
| `make push` | `docker push` the image built by `make image` |
| `make push-linux` / `push-arm` / `push-macos` / `push-windows` | Push the corresponding platform image |
| `make release-linux` / `release-arm` / `release-macos` / `release-windows` | Build **and** push the corresponding platform image |

### Cleanup

`make clean` removes local build artifacts (`makbot-*` binaries) and the
current `IMAGE_TAG` from the local Docker image cache.

## Docker

The `Dockerfile` is a multi-stage build:

1. **Builder** (`golang:1.26`, cross-compiled for `--platform=$BUILDPLATFORM`):
   - Downloads modules, copies source
   - Runs `go test -v ./...`
   - Builds a static binary (`CGO_ENABLED=0`) for the given `TARGETOS`/`TARGETARCH`,
     stamping the version via `-ldflags -X github.com/mananievXAU/makbot.appVersion=${VERSION}`
2. **Final image** (`scratch`):
   - Contains only the compiled `makbot` binary and CA certificates
     (copied from `alpine:latest`) for TLS calls to the Telegram API
   - Entrypoint: `./makbot version`

Build args:

| Arg | Default | Purpose |
|---|---|---|
| `TARGETOS` | `linux` | Target OS for the build |
| `TARGETARCH` | `amd64` | Target architecture for the build |
| `VERSION` | `dev` | Version string baked into the binary |

Build manually, e.g.:
```bash
docker build \
  --build-arg TARGETOS=linux \
  --build-arg TARGETARCH=arm64 \
  --build-arg VERSION=$(git describe --tags --abbrev=0)-$(git rev-parse --short HEAD) \
  -t nananiev/makbot:dev .
```

To actually run the bot (rather than print its version), override the
entrypoint's command:
```bash
docker run -e TELE_TOKEN=your_token nananiev/makbot:dev ./makbot start
```

## Project Structure

```
.
├── main.go            # entrypoint, delegates to cmd.Execute()
├── cmd/
│   ├── root.go         # root Cobra command
│   ├── kbot.go          # "start"/"kbot" command: runs the Telegram bot
│   ├── version.go       # "version" command
│   └── const.go          # shared constants
├── Makefile            # build/test/docker/release automation
├── Dockerfile           # multi-stage container build
└── go.mod / go.sum
```

## Versioning

The application version is baked in at build time from:
- The latest git tag
- The short commit hash

via `-ldflags "-X github.com/mananievXAU/makbot.appVersion=<version>"`.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
