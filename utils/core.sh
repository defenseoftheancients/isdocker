
DOCKER_PEERED_SERVICES=("proxy")

function containsElement {
  local e match="$1"

  shift
  for e; do 
  [[ "$e" == "$match" ]] && return 0; done
  return 1
}

function assertDockerRunning {
  if ! docker system info >/dev/null 2>&1; then
    fatal "Docker does not appear to be running. Please start Docker."
  fi
}

function connectPeeredServices {
  for svc in ${DOCKER_PEERED_SERVICES[@]}; do
    echo "Connecting ${svc} to $1 network"
    (docker network connect "$1" ${svc} 2>&1| grep -v 'already exists in network') || true
  done
}

function disconnectPeeredServices {
  for svc in ${DOCKER_PEERED_SERVICES[@]}; do
    echo "Disconnecting ${svc} from $1 network"
    (docker network disconnect "$1" ${svc} 2>&1| grep -v 'is not connected') || true
  done
}