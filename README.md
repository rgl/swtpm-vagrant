# About

[![Build status](https://github.com/rgl/swtpm-vagrant/workflows/build/badge.svg)](https://github.com/rgl/swtpm-vagrant/actions?query=workflow%3Abuild)

This is a vagrant environment to play with [swtpm](https://github.com/stefanberger/swtpm) (a [Trusted Platform Module (TPM)](https://en.wikipedia.org/wiki/Trusted_Platform_Module) emulator) inside a qemu/kvm VM.

The swtpm binaries packages are used at [rgl/tpm-go-attestation-vagrant](https://github.com/rgl/tpm-go-attestation-vagrant).

# Usage

If you want to use the binary packages execute:

```bash
# enter a root shell.
sudo -i

# install the binaries.
mkdir -p tmp
wget -qO tmp/swtpm-packages.tgz https://github.com/rgl/swtpm-vagrant/releases/download/v0.0.20220427/swtpm-packages.tgz
packages_path='/opt/apt/repo.d/swtpm'
rm -rf $packages_path && install -d $packages_path
tar xf tmp/swtpm-packages.tgz -C $packages_path
bash -c "echo \"deb [trusted=yes] file:$packages_path ./\" >/etc/apt/sources.list.d/swtpm.list"
apt-get update
apt-get install -y swtpm swtpm-tools
install -d -o tss -g tss -m 755 /var/lib/swtpm-localca

# create the swtpm localca.
# NB the localca is created as a side-effect of creating a dummy swtpm instance
#    based on the configuration files at /etc/swtpm* (installed by the
#    swtpm-tools package).
TPMSTATE=tmp/tpmstate
install -d "$TPMSTATE"
swtpm_setup \
    --tpm2 \
    --tpmstate "$TPMSTATE" \
    --create-ek-cert \
    --create-platform-cert \
    --lock-nvram
chown -R tss:tss /var/lib/swtpm-localca
rm -rf "$TPMSTATE"

# exit the root shell.
exit
```

If you want to build them yourself follow the next section.

# Build

Install the base [Ubuntu 20.04 base box](https://github.com/rgl/ubuntu-vagrant).

Launch the environment:

```bash
vagrant up --no-destroy-on-error
```

Then follow the output instructions to launch a nested VM and
play with its TPM.

## Packages

After `vagrant up` the packages are copied to the `tmp/swtpm-packages.tgz` host file.

You can install them as described in the usage section (skip the download part).

## vagrant-libvirt

Install the swtpm packages as described above.

Configure your `Vagrantfile` to [automatically create an emulated TPM for the VM](https://github.com/vagrant-libvirt/vagrant-libvirt#tpm-devices).

# References

* [Trusted Platform Module (Wikipedia)](https://en.wikipedia.org/wiki/Trusted_Platform_Module)
* [Trusted Platform Module (Arch Linux)](https://wiki.archlinux.org/index.php/Trusted_Platform_Module)
* [tpm-js (experiment with a software Trusted Platform Module (TPM) in your browser)](https://google.github.io/tpm-js/)
* [QEMU TPM Device](https://www.qemu.org/docs/master/specs/tpm.html)
* [The QEMU TPM emulator device](https://www.qemu.org/docs/master/specs/tpm.html#the-qemu-tpm-emulator-device)
