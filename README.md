# petalinux-docker-2020.2
Docker Creation repository for petalinux 2020.2






# petalinux-docker

Copy petalinux-v2020.2-final-installer.run file to this folder. Then run:

```
docker build \
  --build-arg INSTALL_FILE=Xilinx_Unified_2020.2_1118_1232.tar.gz \
  --build-arg UBUNTU_MIRROR=dk.archive.ubuntu.com/ubuntu \
  -t vivado-petalinux-2020.2 .

```

After installation, launch petalinux with:

`docker run -it --name vivado-container vivado-petalinux:2020.2`



# Referenced 
 - https://github.com/phwl/docker-vivado
 - https://www.howtoforge.com/how-to-create-docker-images-with-dockerfile-ubuntu-20-04/
 - https://github.com/z4yx/petalinux-docker