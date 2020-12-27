#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# see https://github.com/stefanberger/libtpms/releases
libtpms_url='https://github.com/stefanberger/libtpms.git'
libtpms_ref='v0.7.3'

# see https://github.com/stefanberger/swtpm/releases
swtpm_url='https://github.com/stefanberger/swtpm.git'
swtpm_ref='v0.5.2'

mkdir -p ~/code && cd ~/code
libtpms_path="$PWD/$(echo $(basename $libtpms_url) | sed -E 's,\.git,,g')"
swtpm_path="$PWD/$(echo $(basename $swtpm_url) | sed -E 's,\.git,,g')"
packages_path="/opt/local-apt-packages"

# install dependencies.
apt-get -y install build-essential fakeroot devscripts equivs dpkg-dev

function recreate-packages-repository {
    rm -rf $packages_path && mkdir -p $packages_path
    cp $libtpms_path/../*.deb $packages_path
    (cd $packages_path && dpkg-scanpackages . >Packages)
    echo "deb [trusted=yes] file:$packages_path ./" >/etc/apt/sources.list.d/local-apt-packages.list
    apt-get update
}

# build libtpm.
git clone $libtpms_url
pushd $libtpms_path
git checkout $libtpms_ref
mk-build-deps \
    --install \
    --build-dep \
    '--tool=apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y' \
    debian/control
dpkg-buildpackage -b -us -uc -j$(nproc)
popd
recreate-packages-repository

# build swtpm.
git clone $swtpm_url
pushd $swtpm_path
git checkout $swtpm_ref
mk-build-deps \
    --install \
    --build-dep \
    '--tool=apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y' \
    debian/control
dpkg-buildpackage -b -us -uc -j$(nproc)
popd
recreate-packages-repository
