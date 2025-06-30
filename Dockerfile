# Base image
FROM ubuntu:20.04

# Metadata
LABEL maintainer="olade@sdu.dk"
LABEL version="0.1"
LABEL description="Custom Docker image for mp4d-soc-4-drones Vivado + Petalinux toolchain"

# Disable prompts during install
ARG DEBIAN_FRONTEND=noninteractive
ARG UBUNTU_MIRROR=archive.ubuntu.com
ARG INSTALL_FILE="Xilinx_Unified_2020.2_1118_1232.tar.gz"
ARG gosu_version=1.10

# Locale and environment setup
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    HOME=/home/vivado

# Set up APT mirror and base tools
RUN sed -i.bak "s|archive.ubuntu.com|${UBUNTU_MIRROR}|g" /etc/apt/sources.list && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates curl sudo gnupg2 xorg dbus dbus-x11 \
    ubuntu-gnome-default-settings gtk2-engines lxappearance \
    fonts-ubuntu-font-family-console fonts-droid-fallback \
    locales && \
    locale-gen en_US.UTF-8 && update-locale && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN adduser --disabled-password --gecos '' vivado && \
    usermod -aG sudo vivado && \
    echo "vivado ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install gosu safely
RUN curl -SL "https://github.com/tianon/gosu/releases/download/${gosu_version}/gosu-$(dpkg --print-architecture)" \
      -o /usr/local/bin/gosu && \
    curl -SL "https://github.com/tianon/gosu/releases/download/${gosu_version}/gosu-$(dpkg --print-architecture).asc" \
      -o /usr/local/bin/gosu.asc && \
    gpg --keyserver keyserver.ubuntu.com --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
    gpg --verify /usr/local/bin/gosu.asc && \
    rm -f /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu

# Install tools for Vivado/PetaLinux
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential git gcc-multilib libc6-dev:i386 \
    ocl-icd-opencl-dev libjpeg62-dev \
    python3 python3-pip && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    pip3 install virtualenv && \
    rm -rf /var/lib/apt/lists/*

# Install Vivado (copy installer manually beforehand)
COPY install_config.txt /vivado-installer/
COPY Xilinx_Unified_2020.2_1118_1232.tar.gz /vivado-installer/

RUN mkdir -p /opt/Xilinx && \
    tar -xzf /vivado-installer/Xilinx_Unified_2020.2_1118_1232.tar.gz -C /vivado-installer --strip-components=1 && \
    /vivado-installer/xsetup \
        --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA \
        --batch Install \
        --config /vivado-installer/install_config.txt && \
    rm -rf /vivado-installer

# Entry point script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Make bash default shell
RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# Prepare Vivado user environment
USER vivado
RUN mkdir -p /home/vivado/project && \
    echo "source /opt/Xilinx/petalinux/settings.sh" >> /home/vivado/.bashrc

# Set working directory
WORKDIR /home/vivado/project

# Default command
CMD ["/bin/bash", "-l"]
