# petalinux-docker-2020.2
Docker Creation repository for petalinux 2020.2






# petalinux-docker

Copy petalinux-v2020.2-final-installer.run file to this folder. Then run:

```
docker build \
  --build-arg INSTALL_FILE=Xilinx_Unified_2020.2_1118_1232.tar.gz \
  --build-arg UBUNTU_MIRROR=mirror.cloudflare.com/ubuntu \
  -t vivado-petalinux-2020.2 .

```

After installation, launch petalinux with:

`docker run -ti --rm -e DISPLAY=$DISPLAY --net="host" -v /tmp/.X11-unix:/tmp/.X11-unix -v $HOME/.Xauthority:/home/vivado/.Xauthority -v $HOME/Projects:/home/vivado/project  petalinux:2020.2 /bin/bash`




# Referenced 
 - https://github.com/phwl/docker-vivado
 - https://www.howtoforge.com/how-to-create-docker-images-with-dockerfile-ubuntu-20-04/
 - https://github.com/z4yx/petalinux-docker