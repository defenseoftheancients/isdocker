#!/usr/bin/env bash

ISDOCKER_ENV_PATH="$(pwd -P)"

if test -f "${ISDOCKER_ENV_PATH}/.env"; then
  while true; do
    read -p $'\033[32mA ISDOCKER env file already exists at '"${ISDOCKER_ENV_PATH}/.env"$'; would you like to overwrite? y/n\033[0m ' resp
    case $resp in
      [Yy]*) echo "Overwriting extant .env file"; break;;
      [Nn]*) exit;;
      *) echo "Please answer (y)es or (n)o";;
    esac
  done
fi

if test -f "${ISDOCKER_ENV_PATH}/.env"; then
  > "${ISDOCKER_ENV_PATH}/.env"
fi

ISDOCKER_ENV_NAME="${ISDOCKER_PARAMS[0]:-}"

ENV_INIT_FILE="${ISDOCKER_DIR}/docker/environments/init.env"
if [[ ! -z $ENV_INIT_FILE ]]; then
 cat "${ENV_INIT_FILE}" >> "${ISDOCKER_ENV_PATH}/.env"
fi

sed -i 's|COMPOSE_PROJECT_NAME=.*|COMPOSE_PROJECT_NAME='"$ISDOCKER_ENV_NAME"'|g' "${ISDOCKER_ENV_PATH}/.env"
sed -i 's|WORK_DIR=.*|WORK_DIR='"$ISDOCKER_ENV_PATH"'|g' "${ISDOCKER_ENV_PATH}/.env"