# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM golang:1.26 AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64
ARG VERSION=dev

WORKDIR /go/src/app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go test -v ./...

RUN CGO_ENABLED=0 \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    go build \
        -v \
        -o /out/makbot \
        -ldflags "-X github.com/mananievXAU/makbot.appVersion=${VERSION}"


FROM scratch

WORKDIR /

COPY --from=builder /out/makbot ./makbot

COPY --from=alpine:latest \
    /etc/ssl/certs/ca-certificates.crt \
    /etc/ssl/certs/ca-certificates.crt

ENTRYPOINT ["./makbot", "version"]