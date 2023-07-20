#!/usr/bin/env bash

ISDOCKER_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${ISDOCKER_ENV_PATH}" || exit $?

ISDOCKER_ENV_SHELL_COMMAND=${ISDOCKER_ENV_SHELL_COMMAND:-bash}

trap '' ERR

CONTAINER_CLI=$("$DOCKER_COMMAND" ps --filter "name=${ISDOCKER_ENV_NAME}-cli*" --format "{{.Names}}") 
if [[ ! -z $CONTAINER_CLI ]]; then
    "$DOCKER_COMMAND"  exec -it "${CONTAINER_CLI}" "${ISDOCKER_ENV_SHELL_COMMAND}"
else
    echo "Error"
fi
