#!/usr/bin/env bash

ISDOCKER_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${ISDOCKER_ENV_PATH}" || exit $?
assertDockerRunning

if (( ${#ISDOCKER_PARAMS[@]} == 0 )) || [[ "${ISDOCKER_PARAMS[0]}" == "help" ]]; then
  $ISDOCKER_BIN env --help || exit $? && exit $?
fi

trap '' ERR

export readonly ISDOCKER_DIR_CONFIG_FILE="${ISDOCKER_ENV_PATH}/.isdocker"
DOCKER_COMPOSE_ARGS=()
REQUIRE_CONFIG_FILES=()

appendEnvPartialIfExists "networks"

[[ ${ISDOCKER_NGINX} -eq 1 ]] \
    && appendEnvPartialIfExists "nginx"

[[ ${ISDOCKER_PHP} -eq 1 ]] \
    && appendEnvPartialIfExists "php"

[[ ${ISDOCKER_CLI} -eq 1 ]] \
    && appendEnvPartialIfExists "cli"

[[ ${ISDOCKER_DB} -eq 1 ]] \
    && appendEnvPartialIfExists "db"
  
[[ ${ISDOCKER_SEARCHENGINE} -eq 1 ]] \
    && appendEnvPartialIfExists "search-engine"

[[ ${ISDOCKER_ADMINER} -eq 1 ]] \
    && appendEnvPartialIfExists "adminer"

[[ ${ISDOCKER_CRON} -eq 1 ]] \
    && appendEnvPartialIfExists "cron"

[[ ${ISDOCKER_REDIS} -eq 1 ]] \
    && appendEnvPartialIfExists "redis"

[[ ${ISDOCKER_VARNISH} -eq 1 ]] \
    && appendEnvPartialIfExists "varnish"

[[ ${ISDOCKER_SELENIUM} -eq 1 ]] \
    && appendEnvPartialIfExists "selenium"

[[ ${ISDOCKER_ALLURE} -eq 1 ]] \
    && appendEnvPartialIfExists "allure"

[[ ${ISDOCKER_RABBITMQ} -eq 1 ]] \
    && appendEnvPartialIfExists "rabbitmq"

[[ ${ISDOCKER_XHPROF} -eq 1 ]] \
    && appendEnvPartialIfExists "xhprof"

[[ ${ISDOCKER_BROWSERSYNC} -eq 1 ]] \
    && appendEnvPartialIfExists "browser-sync"

[[ ${ISDOCKER_NEWRELIC} -eq 1 ]] \
    && appendEnvPartialIfExists "newrelic"

[[ ${ISDOCKER_ZOOKEEPER} -eq 1 ]] \
    && appendEnvPartialIfExists "zookeeper"

[[ ${ISDOCKER_BLACKFIRE} -eq 1 ]] \
    && appendEnvPartialIfExists "blackfire"

if [[ -f "${ISDOCKER_DIR_CONFIG_FILE}/isdocker-env.yml" ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${ISDOCKER_DIR_CONFIG_FILE}/isdocker-env.yml")
fi

if [[ "${ISDOCKER_PARAMS[0]}" == "up" ]]; then

    ${DOCKER_COMPOSE_COMMAND} \
        --project-directory "${ISDOCKER_ENV_PATH}" -p "${COMPOSE_PROJECT_NAME}" \
        "${DOCKER_COMPOSE_ARGS[@]}" up --no-start

    connectPeeredServices "$(renderEnvNetworkName)"

    if ! (containsElement "-d" "$@" || containsElement "--detach" "$@"); then
        ISDOCKER_PARAMS=("${ISDOCKER_PARAMS[@]:1}")
        ISDOCKER_PARAMS=(up -d "${ISDOCKER_PARAMS[@]}")
    fi
elif [[ "${ISDOCKER_PARAMS[0]}" == "down" ]]; then
     disconnectPeeredServices "$(renderEnvNetworkName)"
fi

${DOCKER_COMPOSE_COMMAND} \
    --project-directory "${ISDOCKER_ENV_PATH}" -p "${COMPOSE_PROJECT_NAME}" \
    "${DOCKER_COMPOSE_ARGS[@]}" "${ISDOCKER_PARAMS[@]}" "$@"
  