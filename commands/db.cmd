#!/usr/bin/env bash

ISDOCKER_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${ISDOCKER_ENV_PATH}" || exit $?
assertDockerRunning

if [[ ${ISDOCKER_DB:-1} -eq 0 ]]; then
  fatal "Database environment is not used (ISDOCKER_DB=0)."
fi

if (( ${#ISDOCKER_PARAMS[@]} == 0 )) || [[ "${ISDOCKER_PARAMS[0]}" == "help" ]]; then
  $ISDOCKER_BIN db --help || exit $? && exit $?
fi

## load connection information for the mysql service
CONTAINER_DB=$("$DOCKER_COMMAND" ps --filter "name=${COMPOSE_PROJECT_NAME}-db*" --format "{{.ID}}")
if [[ ! ${CONTAINER_DB} ]]; then
    fatal "No container found for db service."
fi

## sub-command execution

case "${ISDOCKER_PARAMS[0]}" in
    import)
        "$DOCKER_COMMAND" exec -i $CONTAINER_DB \
            mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --database "${MYSQL_DATABASE}" < "${ISDOCKER_PARAMS[@]:1}"
        ;;
    *)
        echo -e "\033[31mThe command \"${ISDOCKER_PARAMS[0]}\" does not exist. Please use --help for usage.\033[0m"
        ;;
esac

