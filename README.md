# README #

Welcome to the padavan-fw project

This project aims to improve the supported devices on the software part, allowing power user to take full control over their hardware.
This project was created in hope to be useful, but comes without warranty or support. Installing it will probably void your warranty.
Contributors of this project are not responsible for what happens next. Flash at your own risk!

Original Repository
-------------------
This project is based on the original Padavan firmware project available at:
[https://gitlab.com/hadzhioglu/padavan-ng](https://gitlab.com/hadzhioglu/padavan-ng)


### Compilation Instructions ###

* Install dependencies

```shell
# I recommend building only on OS: Ubuntu Desktop 22.04.4 LTS (Jammy Jellyfish) and Before building the firmware, select "App Updates" and install them. Next, update the packages
sudo apt update
sudo apt upgrade
sudo apt install autoconf autoconf-archive automake autopoint bison build-essential ca-certificates cmake cpio curl doxygen fakeroot flex gawk gettext git gperf help2man htop kmod libblkid-dev libc-ares-dev libcurl4-openssl-dev libdevmapper-dev libev-dev libevent-dev libexif-dev libflac-dev libgmp3-dev libid3tag0-dev libidn2-dev libjpeg-dev libkeyutils-dev libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libogg-dev libsqlite3-dev libssl-dev libtool libtool-bin libudev-dev libunbound-dev libvorbis-dev libxml2-dev locales mc nano pkg-config ppp-dev python3 python3-docutils sshpass texinfo unzip uuid uuid-dev vim wget xxd zlib1g-dev

```
[Automatic Padavan firmware builds using GitHub servers](https://github.com/leftprazz/padavan-builder-workflow)

### Firmware management ###
```shell 
Login details
IP: 192.168.1.1 or http://my.router
User: admin
Password: admin
WiFi name 2.4GHz: Padavan_2.4GHz
WiFi name 5GHz: Padavan_5GHz
WiFi Password 2.4/5GHz: 1234567890
```

# Build Firmware from Source

This procedure is intended to build Padavan updates from sources not available in the Prometheus script. It can be used with any other Padavan Git repository.

We will use a Docker Container for convenience, but you can also use a virtual machine. If using Ubuntu 22.04, ensure that the dependency packages are installed/updated.

1. **Build and Start Container**

   ```shell
   docker build -t ubuntu:fw .
   ```

   ```shell
   docker run -it ubuntu:fw
   ```

2. **Update, Upgrade, and Install Packages**

   ```shell
   apt update && apt upgrade -y && apt -y install gnutls-bin nano autoconf autoconf-archive automake autopoint bison build-essential ca-certificates cmake cpio curl doxygen fakeroot flex gawk gettext git gperf help2man kmod libtool pkg-config zlib1g-dev libgmp3-dev libmpc-dev libmpfr-dev libblkid-dev libjpeg-dev libsqlite3-dev libexif-dev libid3tag0-dev libogg-dev libvorbis-dev libflac-dev libc-ares-dev libcurl4-openssl-dev libdevmapper-dev libev-dev libevent-dev libkeyutils-dev libmpc-dev libmpfr-dev libsqlite3-dev libssl-dev libtool libudev-dev libxml2-dev libncurses5-dev libltdl-dev libtool-bin locales nano netcat pkg-config ppp-dev python3 python3-docutils texinfo unzip uuid uuid-dev wget xxd zlib1g-dev
   ```

3. **Clone Repo**

   ```shell
   git clone https://github.com/leftprazz/padavan-fw.git
   ```

   If you encounter an error like "RPC failed; curl 56 GnuTLS recv error (-9)", try re-cloning the repo or adjust the global parameter:

   ```shell
   git config --global http.postBuffer 1048576000
   ```

4. **Set Fakeroot**

   ```shell
   update-alternatives --set fakeroot /usr/bin/fakeroot-tcp 2>/dev/null
   ```

5. **Build Toolchain**

   ```shell
   cd padavan-fw/toolchain
   ./clean_sources.sh 
   ./build_toolchain.sh
   ```

6. **Copy model board and edit config**

   Replace with your router model.

   ```shell
   cd ../trunk
   cp configs/templates/xiaomi/mi-r1c.config .config
   nano .config
   ```

7. **Enable Configs**

   Enable or disable the settings you want.

   ```shell
   CONFIG_FIRMWARE_INCLUDE_OPENSSL_EXE=y
   CONFIG_FIRMWARE_INCLUDE_OPENSSL_EC=y
   ```

8. **Build Firmware**

   ```shell
   ./clear_tree.sh 
   ./build_firmware.sh
   ```

9. **Copy firmware from container to Host**

   ```shell
   for file in $(docker exec $(docker container ls -a | grep -e 'ubuntu:fw' | grep -e 'Up' | awk '{print $1}') sh -c "ls padavan-fw/trunk/images/*.trx"); do
       docker cp $(docker container ls -a | grep -e 'ubuntu:fw' | grep -e 'Up' | awk '{print $1}'):${file} $HOME
   done
   ```

---

You can use the Prometheus script mounted under a Docker Container to generate older firmware images. Just download the attached Dockerfile in this Git, build and run.

```
docker image build -t prometheus /path/to/Dockerfile
docker run -it --name prometheus <containerID>
```

# DISCLAIMER #
IMPORTANT NOTE!! PLEASE READ IT CAREFULLY!!
# NO WARRANTY OR SUPPORT
This product includes copyrighted third-party software licensed under the terms of the GNU General Public License. Please see The GNU General Public License for the exact terms
and conditions of this license. The firmware or any other product designed or produced by this project may contain in whole or in part pre-release, untested, or not fully tested works.
This may contain errors that could cause failures or loss of data, and may be incomplete or contain inaccuracies. You expressly acknowledge and agree that use of software or any part,
produced by this project, is at Your sole and entire risk.

ANY PRODUCT IS PROVIDED 'AS IS' AND WITHOUT WARRANTY, UPGRADES OR SUPPORT OF ANY KIND. ALL CONTRIBUTORS EXPRESSLY DISCLAIM ALL WARRANTIES AND/OR CONDITIONS, EXPRESS OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES AND/OR CONDITIONS OF SATISFACTORY QUALITY, OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY, OF QUIET ENJOYMENT, AND NONINFRINGEMENT
OF THIRD PARTY RIGHTS.

