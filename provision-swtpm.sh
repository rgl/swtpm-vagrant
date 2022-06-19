#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# install swtpm.
apt-get install -y swtpm swtpm-tools
swtpm --version

# initialize the swtpm localca and a tpm.
# see man swtpm_setup
TPMSTATE="$PWD/mytpm1"
install -d "$TPMSTATE"
swtpm_setup \
    --tpm2 \
    --tpmstate "$TPMSTATE" \
    --create-ek-cert \
    --create-platform-cert \
    --lock-nvram
chown -R tss:tss /var/lib/swtpm-localca

# download the iso to the shared storage.
iso_url=https://github.com/rgl/debian-live-builder-vagrant/releases/download/v20210714/debian-live-20210714-amd64.iso
iso_path=/vagrant/tmp/$(basename $iso_url)
if [[ ! -f $iso_path ]]; then
    mkdir -p $(dirname $iso_path)
    wget -qO $iso_path $iso_url
fi
cd ~
7z x -y $iso_path live/vmlinuz live/initrd.img
cat <<EOF
ssh into the vagrant environment:

    vagrant ssh

switch to root:

    sudo -i

start a swtpm instance in background with:

    export TPMSTATE="\$PWD/mytpm1"
    install -d "\$TPMSTATE"
    swtpm \\
        socket \\
        --tpm2 \\
        --daemon \\
        --tpmstate "dir=\${TPMSTATE}" \\
        --ctrl "type=unixio,path=\${TPMSTATE}/swtpm-sock" \\
        --log "file=\${TPMSTATE}/swtpm.log,level=20"

run a vm with:

    qemu-system-x86_64 \\
        -enable-kvm \\
        -nographic \\
        -cdrom $iso_path \\
        -kernel live/vmlinuz \\
        -initrd live/initrd.img \\
        -append 'boot=live components username=vagrant console=ttyS0' \\
        -net nic \\
        -net user \\
        -m 512 \\
        -rtc base=utc \\
        -chardev "socket,id=devtpm0,path=\${TPMSTATE}/swtpm-sock" \\
        -tpmdev emulator,id=tpm0,chardev=devtpm0 \\
        -device tpm-crb,tpmdev=tpm0

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
    tpm2_getcap properties-fixed
    tpm2_getcap properties-variable
    tpm2_getcap algorithms
    tpm2_getcap commands
    tpm2_getcap ecc-curves

    # list the pcrs and their values.
    tpm2_pcrread

    # get 16 bytes of random values.
    echo "random: \$(tpm2_getrandom --hex 16)"
EOF
