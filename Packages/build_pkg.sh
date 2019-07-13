#!/bin/bash

# Now requiring root to make packages
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root with the command below.
sudo sh \"$0\"" ; exit 1 ; fi

VERSION=$( date +%Y%m%d%H%M )

# Get the absolute path of the directory containing this script
# https://unix.stackexchange.com/questions/9541/find-absolute-path-from-a-script

dir=$( unset CDPATH && cd "$(dirname "$0")" && echo "$PWD" )

# Every user should have read rights

/usr/sbin/chown -R root:wheel "${dir}/payload/"
/bin/chmod -R 755 "${dir}/payload/"

/usr/bin/find "${dir}" -name .DS_Store -delete

# Build package

/usr/bin/pkgbuild --root "${dir}/payload" \
	 --identifier github.cubandave.UEX.installer \
	 --version "$VERSION" \
	 --component-plist "${dir}/UEXresources-component.plist" \
	 "${dir}/UEXresourcesInstaller-${VERSION}.pkg"
