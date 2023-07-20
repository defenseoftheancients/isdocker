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

ISDOCKER_ENV_NAME="${ISDOCKER_PARAMS[0]:-}"

cat > "${ISDOCKER_ENV_PATH}/.env" <<EOF
ISDOCKER_ENV_NAME=$ISDOCKER_ENV_NAME
EOF

ENV_INIT_FILE="${ISDOCKER_DIR}/docker/environments/init.env"
if [[ ! -z $ENV_INIT_FILE ]]; then
 cat "${ENV_INIT_FILE}" >> "${ISDOCKER_ENV_PATH}/.env"
fi