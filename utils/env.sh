function locateEnvPath () {
   
    local ISDOCKER_ENV_PATH="$(pwd -P)"
    while [[ "${ISDOCKER_ENV_PATH}" != "/" ]]; do
    	
        if [[ -f "${ISDOCKER_ENV_PATH}/.env" ]] \
            && grep "^ISDOCKER_ENV_NAME" "${ISDOCKER_ENV_PATH}/.env" >/dev/null
        then
            break
        fi
        ISDOCKER_ENV_PATH="$(dirname "${ISDOCKER_ENV_PATH}")"
     
    done
   
    if [[ "${ISDOCKER_ENV_PATH}" = "/" ]]; then
        
        >&2 echo -e "\033[31mEnvironment config could not be found. Please run \"isdocker env-init\" and try again!\033[0m"
        return 1
    fi

    ## Resolve .env symlink should it exist in project sub-directory allowing sub-stacks to use relative link to parent
    ISDOCKER_ENV_PATH="$(
        cd "$(
            dirname "$(
                (readlink "${ISDOCKER_ENV_PATH}/.env" || echo "${ISDOCKER_ENV_PATH}/.env")
            )"
        )" >/dev/null \
        && pwd
    )"
    echo $ISDOCKER_ENV_PATH
}



function loadEnvConfig () {
    local ISDOCKER_ENV_PATH="${1}"
    eval "$(cat "${ISDOCKER_ENV_PATH}/.env" | sed 's/\r$//g')"

    ISDOCKER_ENV_NAME="${ISDOCKER_ENV_NAME:-}"
    ISDOCKER_ENV_SUBT=""

    case "${OSTYPE:-undefined}" in
        darwin*)
            ISDOCKER_ENV_SUBT=darwin
        ;;
        linux*)
            ISDOCKER_ENV_SUBT=linux
        ;;
        *)
            fatal "Unsupported OSTYPE '${OSTYPE:-undefined}'"
        ;;
    esac
}


function renderEnvNetworkName() {
    echo "${ISDOCKER_ENV_NAME}_internal" | tr '[:upper:]' '[:lower:]'
}

function preHandleImageConfigFile() {
    for IMAGE_NAME in $@
    do
        appendEnvConfig ${IMAGE_NAME}
    done

    for IMAGE_NAME in ${!CONFIG_FILES[@]}
    do
        for CONFIG_FILE in ${CONFIG_FILES[$IMAGE_NAME]}
        do
            if [[ ! " ${CONFIG_FILES_UNIQUE[*]} " =~ " ${CONFIG_FILE} " ]]; then
                CONFIG_FILES_UNIQUE+=("${CONFIG_FILE}") 
            fi
        done
    done
}

function createFileConfigFromEnv() {
    local FILE_PATH="${1}"
    local CONFIG_FILE="${ISDOCKER_DIR}/docker/environments/config/${FILE_PATH}"
    if [[ ! -f "${ISDOCKER_ENV_CONF}" ]]; then
        mkdir -p ${ISDOCKER_ENV_CONF}
    fi
    if test ! -f "${ISDOCKER_ENV_CONF}/${FILE_PATH}"; then
        echo -e "\033[32m ✔\033[0m ${FILE_PATH} file created"; 
        cat "${CONFIG_FILE}" >> "${ISDOCKER_ENV_CONF}/${FILE_PATH}"
    fi
}

function createFileConfig() {
    local FILE_PATH="${1}"
    local CONFIG_FILE="${ISDOCKER_DIR}/docker/environments/config/${FILE_PATH}"
    if [[ ! -f "${ISDOCKER_ENV_CONF}" ]]; then
        mkdir -p ${ISDOCKER_ENV_CONF}
    fi
    
    NEED_TO_CREATE=1
    if test -f "${ISDOCKER_ENV_CONF}/${FILE_PATH}"; then
        while true; do
            read -p $'\033[32mA '"${FILE_PATH}"' file already exists at '"${ISDOCKER_ENV_PATH}/.isdocker"$'; would you like to overwrite? y/n\033[0m ' resp
            case $resp in
                [Yy]*)  NEED_TO_CREATE=1
                        break;;
                [Nn]*)  NEED_TO_CREATE=0
                        break;;
                *) echo "Please answer (y)es or (n)o";;
                esac
        done
    fi    

    if [[ $NEED_TO_CREATE -eq 1 ]]; then
        if test -f "${ISDOCKER_ENV_CONF}/${FILE_PATH}"; then
            echo -e "\033[32m ✔\033[0m  ${FILE_PATH} file overwrited"; 
        else
            echo -e "\033[32m ✔\033[0m ${FILE_PATH} file created"; 
        fi
        cat "${CONFIG_FILE}" >> "${ISDOCKER_ENV_CONF}/${FILE_PATH}"
    fi
}



function appendEnvPartialIfExists () {
    local PARTIAL_NAME="${1}"
    local PARTIAL_PATH=""
    
    for PARTIAL_PATH in \
        "${ISDOCKER_DIR}/docker/environments/${PARTIAL_NAME}.yml" \
        "${ISDOCKER_DIR}/docker/environments/${PARTIAL_NAME}.base.yml" \
        "${ISDOCKER_DIR}/docker/environments/${ISDOCKER_ENV_SUBT}/${PARTIAL_NAME}.yml" \
        "${ISDOCKER_DIR}/docker/environments/${ISDOCKER_ENV_SUBT}/${PARTIAL_NAME}.${ISDOCKER_ENV_SUBT}.yml"
    do
        if [[ -f "${PARTIAL_PATH}" ]]; then
            DOCKER_COMPOSE_ARGS+=("-f" "${PARTIAL_PATH}")
            REQUIRE_CONFIG_FILES+=("${PARTIAL_NAME}")
        fi
    done
}

function appendEnvConfig () {
    local PARTIAL_NAME="${1}"
    local PARTIAL_PATH=""

    for PARTIAL_PATH in \
        "${ISDOCKER_DIR}/docker/environments/${PARTIAL_NAME}.yml" \
        "${ISDOCKER_DIR}/docker/environments/${PARTIAL_NAME}.base.yml" \
        "${ISDOCKER_DIR}/docker/environments/${ISDOCKER_ENV_SUBT}/${PARTIAL_NAME}.yml" \
        "${ISDOCKER_DIR}/docker/environments/${ISDOCKER_ENV_SUBT}/${PARTIAL_NAME}.${ISDOCKER_ENV_SUBT}.yml"
    do
        if [[ -f "${PARTIAL_PATH}" ]]; then
            CONFIG_FILES["$PARTIAL_NAME"]=$(grep -wo '${ISDOCKER_ENV_CONF:-}/.*' ${PARTIAL_PATH} \
        | cut -d ':' -f2 | cut -c 4- );
        fi
    done
}

















