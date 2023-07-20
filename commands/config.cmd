#!/usr/bin/env bash


ISDOCKER_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${ISDOCKER_ENV_PATH}" || exit $?
assertDockerRunning

if (( ${#ISDOCKER_PARAMS[@]} == 0 )) || [[ "${ISDOCKER_PARAMS[0]}" == "help" ]]; then
  $ISDOCKER_BIN env --help || exit $? && exit $?
fi

export readonly ISDOCKER_ENV_CONF="${ISDOCKER_ENV_PATH}/.isdocker"
DOCKER_COMPOSE_ARGS=()
REQUIRE_CONFIG_FILES=()
declare -A CONFIG_FILES=()
declare -A CONFIG_FILES_UNIQUE=()

appendEnvPartialIfExists "networks"

[[ ${ISDOCKER_NGINX} -eq 1 ]] \
        && appendEnvPartialIfExists "nginx"

[[ ${ISDOCKER_PHP} -eq 1 ]] \
    && appendEnvPartialIfExists "php-fpm"

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


if [[ "${ISDOCKER_PARAMS[0]}" == "up" ]]; then
    if [[ ! ${#REQUIRE_CONFIG_FILES[@]} -eq 0  ]]; then
        REQUIRE_CONFIG_FILES_JOIN=$(printf " %s" "${REQUIRE_CONFIG_FILES[@]}")
        preHandleImageConfigFile ${REQUIRE_CONFIG_FILES_JOIN[*]}
        for CONFIG_FILE in "${!CONFIG_FILES_UNIQUE[@]}"
        do
            createFileConfig $CONFIG_FILE
        done
    fi
else
    preHandleImageConfigFile ${ISDOCKER_PARAMS[*]}
    for CONFIG_FILE in "${!CONFIG_FILES_UNIQUE[@]}"
    do
        createFileConfig $CONFIG_FILE
    done
fi




    

