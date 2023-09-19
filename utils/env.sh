function locateEnvPath () {
   
    local ISDOCKER_ENV_PATH="$(pwd -P)"
    while [[ "${ISDOCKER_ENV_PATH}" != "/" ]]; do
    	
        if [[ -f "${ISDOCKER_ENV_PATH}/.env" ]] \
            && grep "^COMPOSE_PROJECT_NAME" "${ISDOCKER_ENV_PATH}/.env" >/dev/null
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

    COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-}"
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
    echo "${COMPOSE_PROJECT_NAME}_internal" | tr '[:upper:]' '[:lower:]'
}

function preHandleImageConfigFile() {
    for IMAGE_NAME in $@
    do
        appendEnvConfig ${IMAGE_NAME}
    done
    for IMAGE_NAME in ${!ISDOCKER_CONF_FILES[@]}
    do
        for CONFIG_FILE in ${ISDOCKER_CONF_FILES[$IMAGE_NAME]}
        do
        if [[ ! " ${ISDOCKER_CONF_FILES_UNIQUE[*]} " =~ " ${CONFIG_FILE} " ]]; then
          
            ISDOCKER_CONF_FILES_UNIQUE+=("${CONFIG_FILE}")
        fi
        done
    done
}

function createFileConfig() {
    local FILE_PATH="${1}"
    local CONFIG_FILE="${ISDOCKER_DIR}/docker/environments/config/${FILE_PATH}"
    if [[ ! -f "${ISDOCKER_DIR_CONFIG_FILE}" ]]; then
        mkdir -p ${ISDOCKER_DIR_CONFIG_FILE}
    fi

    NEED_TO_CREATE=1
    if test -f "${ISDOCKER_DIR_CONFIG_FILE}/${FILE_PATH}"; then
        while true; do
            read -p $'\033[32mA '"${FILE_PATH}"' file already exists at '"${ISDOCKER_DIR_CONFIG_FILE}"$'; would you like to overwrite? y/n\033[0m ' resp
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
        if test -f "${ISDOCKER_DIR_CONFIG_FILE}/${FILE_PATH}"; then
            echo -e "\033[32m ✔\033[0m  ${FILE_PATH} file overwrited"; 
        else
            echo -e "\033[32m ✔\033[0m ${FILE_PATH} file created"; 
        fi
        cat "${CONFIG_FILE}" >> "${ISDOCKER_DIR_CONFIG_FILE}/${FILE_PATH}"
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
            ISDOCKER_CONF_FILES["$PARTIAL_NAME"]=$(grep -wo '${ISDOCKER_ENV_CONF:-}/.*' ${PARTIAL_PATH} \
        | cut -d ':' -f2 | cut -c 4- );
        fi
    done
}

function initIsdockerEnvFile () {
    if [[ ! -f "${ISDOCKER_DIR_CONFIG_FILE}" ]]; then
        mkdir -p ${ISDOCKER_DIR_CONFIG_FILE}
    fi
   
    touch ${ISDOCKER_DIR_CONFIG_FILE}/isdocker-env.yml
    cat >> "${ISDOCKER_DIR_CONFIG_FILE}/isdocker-env.yml" <<EOF
version: '$COMPOSE_FILE_VERSION'

services:
EOF

}

function parse_yaml {
    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
    sed -ne "s|,$s\]$s\$|]|" \
        -e ":1;s|^\($s\)\($w\)$s:$s\[$s\(.*\)$s,$s\(.*\)$s\]|\1\2: [\3]\n\1  - \4|;t1" \
        -e "s|^\($s\)\($w\)$s:$s\[$s\(.*\)$s\]|\1\2:\n\1  - \3|;p" $1 | \
    sed -ne "s|,$s}$s\$|}|" \
        -e ":1;s|^\($s\)-$s{$s\(.*\)$s,$s\($w\)$s:$s\(.*\)$s}|\1- {\2}\n\1  \3: \4|;t1" \
        -e    "s|^\($s\)-$s{$s\(.*\)$s}|\1-\n\1  \2|;p" | \
    sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)-$s[\"']\(.*\)[\"']$s\$|\1$fs$fs\2|p" \
        -e "s|^\($s\)-$s\(.*\)$s\$|\1$fs$fs\2|p" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" | \

    awk -F$fs 'BEGIN{ split("enviroment volumes labels", UNIQUE_KEY, " "); } {
        indent = length($1)/2;
        vname[indent] = $2;
        for (i in vname) {if (i > indent) {delete vname[i]; idx[i]=0}}

        if(length($2)== 0){  vname[indent]= ++idx[indent] };
        if (length($3) > 0) {
            if (index($3, "ISDOCKER_ENV_CONF") != 0) {
                vn=""; 
                for (i = indent-1; i>= 0; i--) { 
                    if (vname[i] != "" && !(vname[i] ~ /^[-+]?[0-9]+$/)) {
                        vn=vname[i];
                        break;
                    } 
                }
                gsub("\${ISDOCKER_ENV_CONF:-}", "./.isdocker", $3)
                if( vname[indent] ~ /^[-+]?[0-9]+$/ ) {
                    for (i in UNIQUE_KEY) {
                        if (UNIQUE_KEY[i] == vn) {
                            {printf ("        %s:\n", vn) >> "'$ISDOCKER_DIR_CONFIG_FILE'" "/isdocker-env.yml" };
                            UNIQUE_KEY[i] = "";
                            break;
                        }
                    }
                    {printf ("        - %s\n", $3) >> "'$ISDOCKER_DIR_CONFIG_FILE'" "/isdocker-env.yml" }
                }
                else {
                    {printf ("        %s: %s\n", vname[indent], $3) >> "'$ISDOCKER_DIR_CONFIG_FILE'" "/isdocker-env.yml" }
                }
            }
      }
   }'
}

function appendIsdockerEnvFile () {
    local IMAGE_NAME=$1
    local CONFIG_FILES=$2

    if [[ ! -s ${ISDOCKER_DIR_CONFIG_FILE}/isdocker-env.yml ]]; then
    cat >> "${ISDOCKER_DIR_CONFIG_FILE}/isdocker-env.yml" <<EOF
version: '$COMPOSE_FILE_VERSION'

services:
EOF
    fi
    cat >> "${ISDOCKER_DIR_CONFIG_FILE}/isdocker-env.yml" <<EOF
    $IMAGE_NAME:
EOF
    parse_yaml ${ISDOCKER_DIR}/docker/environments/${IMAGE_NAME}.base.yml
}














