#!/bin/bash

set -o xtrace

docker rmi localhost/postiz localhost/postiz-devcontainer || true
docker build -t localhost/postiz -f Dockerfile.slim .
docker build -t localhost/postiz-devcontainer -f Dockerfile.dev .
