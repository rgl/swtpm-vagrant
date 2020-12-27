#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# install swtpm.
apt-get install -y swtpm swtpm-tools
swtpm --version

# initialize a tpm.
# see man swtpm_setup
export XDG_CONFIG_HOME=~/.config
mkdir -p $XDG_CONFIG_HOME
cat >$XDG_CONFIG_HOME/swtpm_setup.conf <<'EOF'
# Program invoked for creating certificates
create_certs_tool= /usr/share/swtpm/swtpm-localca
create_certs_tool_config = ${XDG_CONFIG_HOME}/swtpm-localca.conf
create_certs_tool_options = ${XDG_CONFIG_HOME}/swtpm-localca.options
EOF
cat >$XDG_CONFIG_HOME/swtpm-localca.conf <<'EOF'
statedir = ${XDG_CONFIG_HOME}/var/lib/swtpm-localca
signingkey = ${XDG_CONFIG_HOME}/var/lib/swtpm-localca/signkey.pem
issuercert = ${XDG_CONFIG_HOME}/var/lib/swtpm-localca/issuercert.pem
certserial = ${XDG_CONFIG_HOME}/var/lib/swtpm-localca/certserial
EOF
cat >$XDG_CONFIG_HOME/swtpm-localca.options <<'EOF'
--platform-manufacturer Ubuntu
--platform-model QEMU
--platform-version 4.2
EOF
mkdir -p ${XDG_CONFIG_HOME}/mytpm1
swtpm_setup \
    --tpm2 \
    --tpmstate ${XDG_CONFIG_HOME}/mytpm1 \
    --create-ek-cert \
    --create-platform-cert \
    --lock-nvram

# download the iso to the shared storage.
iso_url=https://github.com/rgl/debian-live-builder-vagrant/releases/download/v20200831/debian-live-20200831-amd64.iso
iso_path=/vagrant/tmp/$(basename $iso_url)
if [[ ! -f $iso_path ]]; then
    mkdir -p $(dirname $iso_path)
    wget -qO $iso_path $iso_url
fi
7z x -y $iso_path live/vmlinuz live/initrd.img
cat <<'EOF'
switch to root:

    sudo -i

start a swtpm instance in background with:

    export XDG_CONFIG_HOME=~/.config
    swtpm \
        socket \
        --tpm2 \
        --daemon \
        --tpmstate dir=${XDG_CONFIG_HOME}/mytpm1 \
        --ctrl type=unixio,path=${XDG_CONFIG_HOME}/mytpm1/swtpm-sock \
        --log file=${XDG_CONFIG_HOME}/mytpm1.log,level=20

run a vm with:

    qemu-system-x86_64 \
        -enable-kvm \
        -nographic \
        -cdrom $iso_path \
        -kernel live/vmlinuz \
        -initrd live/initrd.img \
        -append 'boot=live components username=vagrant console=ttyS0' \
        -net nic \
        -net user \
        -m 512 \
        -rtc base=utc \
        -chardev socket,id=devtpm0,path=${XDG_CONFIG_HOME}/mytpm1/swtpm-sock \
        -tpmdev emulator,id=tpm0,chardev=devtpm0 \
        -device tpm-tis,tpmdev=tpm0

**NB** type "ctrl-a h" to see the qemu emulator help
**NB** type "ctrl-a x" to quit the qemu emulator
**NB** see https://github.com/qemu/qemu/blob/master/docs/specs/tpm.txt

login into the vm with:

    username: vagrant
    password: vagrant

test the tpm:

    # switch to root.
    sudo -i

    # get capabilities.
    tpm2_getcap --capability properties-fixed
    tpm2_getcap --capability properties-variable
    tpm2_getcap --capability algorithms
    tpm2_getcap --capability commands
    tpm2_getcap --capability ecc-curves

    # list the pcrs and their values.
    tpm2_pcrlist

    # get 16 bytes of random values.
    tpm2_getrandom 16
EOF
