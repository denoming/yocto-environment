#!/usr/bin/env bash

SDK_USER=sdkuser
SDK_DIR=""
SDK_URL=""
SDK_INSTALL=FALSE
DOCKER_FILE="Dockerfile.esdk"
DOCKER_IMAGE=my/esdk

#--------- Setup ---------

# Setup credential volumes
CREDENTIAL_VOLUMES=""
if [ -e $HOME/.netrc ]; then
    CREDENTIAL_VOLUMES="${CREDENTIAL_VOLUMES} -v ${HOME}/.netrc:/home/${SDK_USER}/.netrc"
fi
if [ -e $HOME/.gitconfig ]; then
    CREDENTIAL_VOLUMES="${CREDENTIAL_VOLUMES} -v ${HOME}/.gitconfig:/home/${SDK_USER}/.gitconfig"
fi
if [ -e $HOME/.config/git ]; then
    CREDENTIAL_VOLUMES="${CREDENTIAL_VOLUMES} -v ${HOME}/.config/git:/home/${SDK_USER}/.config/git"
fi
if [ -e $HOME/.wgetrc ]; then
    CREDENTIAL_VOLUMES="${CREDENTIAL_VOLUMES} -v ${HOME}/.wgetrc:/home/${SDK_USER}/.wgetrc"
fi
if [ -e $HOME/.ssh ]; then
    CREDENTIAL_VOLUMES="${CREDENTIAL_VOLUMES} -v ${HOME}/.ssh:/home/${SDK_USER}/.ssh"
fi

# Setup ssh-agent
eval $(ssh-agent)

# Add private ssh keys
grep --null -slR -e "RSA PRIVATE" -e "DSA PRIVATE" -e "OPENSSH PRIVATE" ~/.ssh/ | xargs --null ssh-add
SSH_AGENT_ARGS=" -v $(dirname $SSH_AUTH_SOCK):$(dirname $SSH_AUTH_SOCK) -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK"

#--------- Functions ---------

function buildImage()
{
    if [[ "$(docker images -q ${DOCKER_IMAGE} 2> /dev/null)" == "" ]]; then
        echo "Building - ${DOCKER_IMAGE}"
        BUILD_CMD="docker build --ssh default -t ${DOCKER_IMAGE} -f ${DOCKER_FILE} ."
        echo ${BUILD_CMD}
        ${BUILD_CMD}
    fi
}

function runImage()
{
    if [[ ! -d ${SDK_DIR} ]]; then
        echo "Creating - ${DOCKER_IMAGE}"
        mkdir -p ${SDK_DIR}
    fi

    if [[ ${SDK_INSTALL} = TRUE ]]; then
        echo "Running (install) - ${DOCKER_IMAGE}"
        RUN_CMD="docker run --rm -it $SSH_AGENT_ARGS $CREDENTIAL_VOLUMES --net=host -v ${SDK_DIR}:/workdir ${DOCKER_IMAGE} --url ${SDK_URL}"
    else 
        echo "Running - ${DOCKER_IMAGE}"
        RUN_CMD="docker run --rm -it $SSH_AGENT_ARGS $CREDENTIAL_VOLUMES --net=host -v ${SDK_DIR}:/workdir ${DOCKER_IMAGE}"
    fi

    echo ${RUN_CMD}
    ${RUN_CMD}
}

#--------- Arguments handling ---------

while [[ $# -gt 0 ]]; do
    case $1 in
    -i|--install)
        SDK_INSTALL=TRUE
        shift
        ;;
    -d|--dir)
        SDK_DIR="$2"
        shift
        shift
        ;;
    -u|--url)
        SDK_URL="$2"
        shift
        shift
        ;;
    -*|--*)
        echo "Unknown option $1"
        exit 1
        ;;            
    esac
done

buildImage
runImage
