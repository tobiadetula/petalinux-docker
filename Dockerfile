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
RUN echo "[INFO] Setting up base tools and locales..." && \
    sed -i.bak "s|archive.ubuntu.com|${UBUNTU_MIRROR}|g" /etc/apt/sources.list && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates curl sudo gnupg2 xorg dbus dbus-x11 \
    ubuntu-gnome-default-settings gtk2-engines lxappearance \
    fonts-ubuntu-font-family-console fonts-droid-fallback apt-utils\
    locales && \
    locale-gen en_US.UTF-8 && update-locale && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN echo "[INFO] Creating user vivado..." && \
    adduser --disabled-password --gecos '' vivado && \
    usermod -aG sudo vivado && \
    echo "vivado ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install gosu safely
RUN echo "[INFO] Installing gosu..." && \
    curl -SL "https://github.com/tianon/gosu/releases/download/${gosu_version}/gosu-$(dpkg --print-architecture)" \
      -o /usr/local/bin/gosu && \
    curl -SL "https://github.com/tianon/gosu/releases/download/${gosu_version}/gosu-$(dpkg --print-architecture).asc" \
      -o /usr/local/bin/gosu.asc && \
    gpg --keyserver keyserver.ubuntu.com --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
    gpg --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
    rm -f /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu


# Message indicating installation of Linux packages
RUN echo "[INFO] Installing Linux packages and Vivado dependencies..."

# Install tools for Vivado/PetaLinux
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    man-db build-essential git gcc-multilib libc6-dev:i386 \
    ocl-icd-opencl-dev libjpeg62-dev \
    python3 python3-pip file xz-utils perl sed unzip pv \
    libtinfo5 libncurses5 libusb-1.0-0 libxrender1 libxi6 libxtst6 \
    libsm6 libxext6 libxrandr2 libglu1-mesa libcanberra-gtk-module \
    lib32z1 lib32stdc++6 lib32gcc1 libssl-dev zlib1g:i386 libstdc++6:i386 \
    libncurses5:i386 libselinux1 net-tools iproute2 iptables \
    chrpath cpio bc diffstat gawk && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    pip3 install virtualenv && \
    rm -rf /var/lib/apt/lists/*

# Copying Vivado installer to Documents directory
RUN echo "Copying Vivado installer..." 

RUN mkdir -p /home/vivado/Documents/vivado-installer
COPY install_config.txt /home/vivado/Documents/vivado-installer/
RUN apt-get update && apt-get install -y pv
COPY Xilinx_Unified_2020.2_1118_1232.tar.gz /home/vivado/Documents/vivado-installer/Xilinx_Unified_2020.2_1118_1232.tar.gz
RUN pv /home/vivado/Documents/vivado-installer/Xilinx_Unified_2020.2_1118_1232.tar.gz > /dev/null

# Set proper ownership for vivado user
RUN chown -R vivado:vivado /home/vivado/Documents/vivado-installer


# Installing Xilinx Vivado and PetaLinux tools
RUN echo "Installing Xilinx Vivado and PetaLinux tools..."

RUN echo "[INFO] Extracting and installing Vivado and Vitis..." 
RUN mkdir -p /tools/Xilinx && \
    tar -xzf /home/vivado/Documents/vivado-installer/Xilinx_Unified_2020.2_1118_1232.tar.gz -C /home/vivado/Documents/vivado-installer --strip-components=1 && \
    /home/vivado/Documents/vivado-installer/xsetup \
        --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA \
        --batch Install \
        --config /home/vivado/Documents/vivado-installer/install_config.txt \
        --xdebug

COPY install_config_petalinux.txt /home/vivado/Documents/vivado-installer/
RUN echo "[INFO] Installing PetaLinux tools..." 
RUN /home/vivado/Documents/vivado-installer/xsetup \
    --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA \
    --batch Install \
    --config /home/vivado/Documents/vivado-installer/install_config_petalinux.txt \
    --xdebug

RUN echo "[INFO] Removing installer..."

RUN rm -rf /home/vivado/Documents/vivado-installer/* && \
    rmdir /home/vivado/Documents/vivado-installer && \
    echo "Installer removed successfully."

RUN echo "Installation completed. Moving on to entry point setup."

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
    # Note: Uncomment the line below after manually installing PetaLinux
    echo "source /tools/Xilinx/petalinux/settings.sh" >> /home/vivado/.bashrc && \
    # Add Vivado settings to .bashrc
    echo "source /tools/Xilinx/Vivado/2020.2/settings64.sh" >> /home/vivado/.bashrc

# Set working directory
WORKDIR /home/vivado/project


# Create Documents folder and clone repo
USER root
RUN echo "Creating Documents folder and cloning repository..."
RUN mkdir -p /home/vivado/Documents && \
    git clone https://github.com/DIII-SDU-Group/MPSoC4Drones.git /home/vivado/Documents/mpsoc4drones-2020 && \
    chown -R vivado:vivado /home/vivado/Documents/mpsoc4drones-2020
# Set environment variables for Vivado and PetaLinux


USER vivado
WORKDIR /home/vivado/Documents/mpsoc4drones-2020
RUN source scripts/settings.sh
RUN echo "source /home/vivado/Documents/mpsoc4drones-2020/scripts/settings.sh" >> ~/.bashrc
# Default command
CMD ["/bin/bash", "-l"]
