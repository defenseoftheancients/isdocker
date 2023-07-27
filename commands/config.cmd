#!/usr/bin/env bash

ISDOCKER_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${ISDOCKER_ENV_PATH}" || exit $?
assertDockerRunning

if (( ${#ISDOCKER_PARAMS[@]} == 0 )) || [[ "${ISDOCKER_PARAMS[0]}" == "help" ]]; then
  $ISDOCKER_BIN env --help || exit $? && exit $?
fi

export readonly ISDOCKER_DIR_CONFIG_FILE="${ISDOCKER_ENV_PATH}/.isdocker"
declare -A ISDOCKER_CONF_FILES=()
declare -A ISDOCKER_CONF_FILES_UNIQUE=()

preHandleImageConfigFile ${ISDOCKER_PARAMS[*]}
if [[ ! ${#ISDOCKER_CONF_FILES_UNIQUE[@]} -eq 0 ]]; then
  if [[ ! -f "${ISDOCKER_DIR_CONFIG_FILE}/isdocker-env.yml" ]]; then
    initIsdockerEnvFile
  fi
fi

for CONFIG_FILE in "${!ISDOCKER_CONF_FILES_UNIQUE[@]}"
do
  createFileConfig $CONFIG_FILE
done

for IMAGE_NAME in ${!ISDOCKER_CONF_FILES[@]}
do
  appendIsdockerEnvFile $IMAGE_NAME {ISDOCKER_CONF_FILES[$IMAGE_NAME]}
done


    

