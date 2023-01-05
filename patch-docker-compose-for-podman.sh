#!/usr/bin/env bash
#
# This script patches the docker-compose.yml for usage with podman.
# Since the sysctl option cannot be set and podman needs additional privileges to bind
# to ports lower than 1024, the following options need to be set:
#
#   sudo sysctl net.ipv4.ip_unprivileged_port_start=25
#   sudo sysctl net.core.somaxconn=4096
#
# Ensure that these options are made persistent.

if [[ ! -f "docker-compose.yml.bak" ]]; then
    # Create a backup (just in case)
    cp docker-compose.yml docker-compose.yml.bak

    # Apply the patches to get it to work with Podman
    patch docker-compose.yml < patch-docker-compose-for-podman.patch

    # Use the podman socket
    sed -i -e "s#/var/run/docker.sock:/var/run/docker.sock#/run/user/${UID}/podman/podman.sock:/var/run/docker.sock#g" docker-compose.yml
else
    echo "docker-compose.yml.bak already exists, docker-compose.yml is probably patched already"
fi

