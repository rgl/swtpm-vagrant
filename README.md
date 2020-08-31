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
