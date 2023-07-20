#!/usr/bin/env bash

if [[ -f "${ISDOCKER_CMD_HELP}" ]]; then
  source "${ISDOCKER_CMD_HELP}"
else
  source "${ISDOCKER_DIR}/commands/usage.help"
fi

echo -e "${ISDOCKER_USAGE}";
exit 1
