#!/bin/env bash

# for systems with podman, replace with docker when necessary
podman network create --driver bridge tools
