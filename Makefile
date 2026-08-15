APP = $(shell basename $(shell git remote get-url origin) .git)
REGISTRY = nananiev
VERSION = $(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)
IMAGE_TAG = $(REGISTRY)/$(APP):$(VERSION)-$(TARGETOS)-$(TARGETARCH)
CGO ?= 0
BINARY ?= makbot

format:
	gofmt -s -w ./

fetch-deps:
	go get

test:
	go test -v

linux: fetch-deps format test
	CGO_ENABLED=$(CGO) \
	GOOS=linux \
	GOARCH=amd64 \
	go build -v \
		-o $(BINARY)-linux-amd64 \
		-ldflags "-X github.com/mananievXAU/makbot.appVersion=$(VERSION)"


macos: fetch-deps format test
	CGO_ENABLED=$(CGO) \
	GOOS=darwin \
	GOARCH=arm64 \
	go build -v \
		-o $(BINARY)-darwin-arm64 \
		-ldflags "-X github.com/mananievXAU/makbot.appVersion=$(VERSION)"

windows: fetch-deps format test
	CGO_ENABLED=$(CGO) \
	GOOS=windows \
	GOARCH=amd64 \
	go build -v \
		-o $(BINARY)-windows-amd64.exe \
		-ldflags "-X github.com/mananievXAU/makbot.appVersion=$(VERSION)"

image-linux: TARGETOS=linux
image-linux: TARGETARCH=amd64
image-linux: image

image-arm: TARGETOS=linux
image-arm: TARGETARCH=arm64
image-arm: image

image-macos: TARGETOS=darwin
image-macos: TARGETARCH=arm64
image-macos: image

image-windows: TARGETOS=windows
image-windows: TARGETARCH=amd64
image-windows: image

image:
	docker build \
		--build-arg TARGETOS=$(TARGETOS) \
		--build-arg TARGETARCH=$(TARGETARCH) \
		--build-arg VERSION=$(VERSION) \
		-t $(IMAGE_TAG) \
		.

push:
	docker push $(IMAGE_TAG)

push-linux: TARGETOS=linux
push-linux: TARGETARCH=amd64
push-linux: push

push-arm: TARGETOS=linux
push-arm: TARGETARCH=arm64
push-arm: push

push-macos: TARGETOS=darwin
push-macos: TARGETARCH=arm64
push-macos: push

push-windows: TARGETOS=windows
push-windows: TARGETARCH=amd64
push-windows: push

release-linux: image-linux push-linux
release-arm: image-arm push-arm
release-macos: image-macos push-macos
release-windows: image-windows push-windows

clean:
	rm -f $(BINARY)-linux-amd64
	rm -f $(BINARY)-linux-arm64
	rm -f $(BINARY)-darwin-arm64
	rm -f $(BINARY)-windows-amd64.exe
	docker rmi $(IMAGE_TAG)