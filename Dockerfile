FROM ubuntu:20.04

# Enable non-interactive mode
ARG DEBIAN_FRONTEND=noninteractive

# Configure time zone
ENV TZ=Europe/Kiev

# Install required packages for the build host
RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y vim gawk wget curl git git-lfs diffstat unzip texinfo lz4 zstd \
    gcc-multilib g++-multilib build-essential chrpath socat cpio \
    python3 python3-pip python3-pexpect python3-git python3-jinja2 python3-subunit python-is-python3 \
    xz-utils debianutils iputils-ping pylint3 xterm \
    mesa-common-dev libegl1-mesa libsdl1.2-dev

# Install "repo" tool (used by many Yocto-based projects)
RUN curl -o /usr/local/bin/repo http://storage.googleapis.com/git-repo-downloads/repo && \
    chmod a+x /usr/local/bin/repo

# Configure locale
RUN apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# Specify locale environment variables
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
