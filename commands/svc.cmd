#!/usr/bin/env bash


if (( ${#ISDOCKER_PARAMS[@]} == 0 )) || [[ "${ISDOCKER_PARAMS[0]}" == "help" ]]; then
  $ISDOCKER_BIN svc --help || exit $? && exit $?
fi

trap '' ERR

DOCKER_COMPOSE_ARGS=()

DOCKER_COMPOSE_ARGS+=("-f")
DOCKER_COMPOSE_ARGS+=("${ISDOCKER_DIR}/docker/docker-compose.yml")

if [[ "${ISDOCKER_PARAMS[0]}" == "up" ]]; then
    if ! (containsElement "-d" "$@" || containsElement "--detach" "$@"); then
        ISDOCKER_PARAMS=("${ISDOCKER_PARAMS[@]:1}")
        ISDOCKER_PARAMS=(up -d "${ISDOCKER_PARAMS[@]}")
    fi
fi

ISDOCKER_SERVICE_DIR={ISDOCKER_DIR} ${DOCKER_COMPOSE_COMMAND} \
    -p is_docker \
    "${DOCKER_COMPOSE_ARGS[@]}" "${ISDOCKER_PARAMS[@]}" "$@"

if [[ "${ISDOCKER_PARAMS[0]}" == "up" ]]; then
    for network in $(docker network ls -f label=dev.isdocker.environment.name --format {{.Name}}); do
        connectPeeredServices "${network}"
    done
fi

