# About

This is a vagrant environment to play with [swtpm](https://github.com/stefanberger/swtpm) (a [Trusted Platform Module (TPM)](https://en.wikipedia.org/wiki/Trusted_Platform_Module) emulator) inside a qemu/kvm VM.

# Usage

Install the base [Ubuntu 20.04 base box](https://github.com/rgl/ubuntu-vagrant).

Launch the environment:

```bash
vagrant up --no-destroy-on-error
```

Then follow the output instructions to launch a nested VM and
play with its TPM.

## Packages

After `vagrant up` the packages are copied to the `tmp/swtpm-packages.tgz` host file.

You can install them with:

```bash
packages_path='/opt/apt/repo.d/swtpm'
sudo rm -rf $packages_path && sudo install -d $packages_path
sudo tar xf tmp/swtpm-packages.tgz -C $packages_path
sudo bash -c "echo \"deb [trusted=yes] file:$packages_path ./\" >/etc/apt/sources.list.d/swtpm.list"
sudo apt-get update
sudo apt-get install -y swtpm swtpm-tools
sudo install -d -o tss -g tss -m 700 /var/lib/swtpm-localca
swtpm --version
```

## vagrant-libvirt

Install the swtpm packages as described above.

Configure your `Vagrantfile` to [automatically create an emulated TPM for the VM](https://github.com/vagrant-libvirt/vagrant-libvirt#tpm-devices).
