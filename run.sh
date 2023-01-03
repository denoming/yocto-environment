#!/usr/bin/env bash

#--------- Setup ---------

WORKDIR=""
if [ "$1" != "" ]; then
    WORKDIR=$1
else
    echo "Please specify worker directory"
    exit 1  
fi

DOCKER_FILE="Dockerfile"
if [ "$2" != "" ]; then
    DOCKER_FILE=$1
fi

DOCKER_IMAGE=my/yocto
if [ "$3" != "" -a "$DOCKER_FILE" = "Dockerfile" ]; then
    DOCKER_IMAGE=$2
fi

# Setup credential volumes
CREDENTIAL_VOLUMES=""
if [ -e $HOME/.netrc ]; then
    CREDENTIAL_VOLUMES="${CREDENTIAL_VOLUMES} -v ${HOME}/.netrc:${HOME}/.netrc"
fi
if [ -e $HOME/.gitconfig ]; then
    CREDENTIAL_VOLUMES="${CREDENTIAL_VOLUMES} -v ${HOME}/.gitconfig:${HOME}/.gitconfig"
fi
if [ -e $HOME/.config/git ]; then
    CREDENTIAL_VOLUMES="${CREDENTIAL_VOLUMES} -v ${HOME}/.config/git:${HOME}/.config/git"
fi
if [ -e $HOME/.wgetrc ]; then
    CREDENTIAL_VOLUMES="${CREDENTIAL_VOLUMES} -v ${HOME}/.wgetrc:${HOME}/.wgetrc"
fi
if [ -e $HOME/.ssh ]; then
    CREDENTIAL_VOLUMES="${CREDENTIAL_VOLUMES} -v ${HOME}/.ssh:${HOME}/.ssh"
fi

# Setup ssh-agent
eval $(ssh-agent)

# Add private ssh keys
grep --null -slR -e "RSA PRIVATE" -e "DSA PRIVATE" -e "OPENSSH PRIVATE" ~/.ssh/ | xargs --null ssh-add
SSH_AGENT_ARGS=" -v $(dirname $SSH_AUTH_SOCK):$(dirname $SSH_AUTH_SOCK) -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK"

#--------- Functions ---------

function createImageFile()
{
    ID_U=$(id -u)
    ID_G=$(id -g)

    cat <<EOF > Dockerfile.user
FROM $DOCKER_IMAGE

USER root
RUN groupdel $USER || true
RUN userdel -r -f $USER || true && rm -rf /home/$USER
RUN groupadd -f -g $ID_G $USER
RUN useradd -l -g $ID_G -u $ID_U -ms /bin/bash $USER
RUN echo $USER:$USER | chpasswd
RUN echo '$USER ALL=(ALL) NOPASSWD:SETENV: ALL' > /etc/sudoers.d/$USER || true

USER $USER:$USER
COPY docker-entrypoint.sh /
COPY gitconfig /home/$USER
ENTRYPOINT ["/docker-entrypoint.sh"]
EOF
}

function buildImage()
{
    echo "Enable BuildKit"
    export DOCKER_BUILDKIT=1

    if [[ "$(docker images -q $DOCKER_IMAGE 2> /dev/null)" == "" ]]; then
        echo "Building - ${DOCKER_IMAGE}"
        BUILD_CMD="docker build --ssh default -t $DOCKER_IMAGE -f $DOCKER_FILE ."
        echo $BUILD_CMD
        $BUILD_CMD
    fi

    echo "Building - ${DOCKER_IMAGE}-user"
    BUILD_CMD="docker build --ssh default -t $DOCKER_IMAGE-user -f Dockerfile.user ."
    echo $BUILD_CMD
    $BUILD_CMD
}

function runImage()
{
    echo "Running - ${DOCKER_IMAGE}-user"
    RUN_CMD="docker run --user $(id -u):$(id -g) --rm -it $SSH_AGENT_ARGS $CREDENTIAL_VOLUMES --network=host -v $PWD:$PWD -w $PWD/$WORKDIR -e YOCTO_ENTRYPOINT=$PWD/$WORKDIR/yocto-entrypoint.sh $DOCKER_IMAGE-user"
    echo $RUN_CMD
    $RUN_CMD
}

#--------- Main body ---------

if [ ! -d "$WORKDIR" ]; then
    echo "Specified worker directory doesn't exist"
    exit 1
fi

if [ ! -f "$WORKDIR/yocto-entrypoint.sh" ]; then
    echo "Specified worker directory doesn't contain yocto entrypoint file"
    exit 1
fi

createImageFile
buildImage
runImage
