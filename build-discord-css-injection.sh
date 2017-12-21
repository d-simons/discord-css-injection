#!/bin/bash -e
# Title: spm
# Description: Downloads and installs AppImages and precompiled tar archives.  Can also upgrade and remove installed packages.
# Dependencies: GNU coreutils, tar, wget
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only
# Script for building releases of discord-css-injection

BUILD_DIR="/run/media/simonizor/0d208b29-3b29-4ffc-99be-1043b9f3c258/github/all-releases"
VERSION="0.0.2"
mkdir -p "$BUILD_DIR"/deps/extracted
mkdir "$BUILD_DIR"/discord-css-injection.AppDir

debiangetlatestdebfunc () {
    DEB_RELEASE="$1"
    DEB_ARCH="$2"
    DEB_NAME="$3"
    LATEST_DEB_URL="$(wget "https://packages.debian.org/$DEB_RELEASE/$DEB_ARCH/$DEB_NAME/download" -qO - | grep "<li>*..*$DEB_ARCH.deb" | cut -f2 -d'"' | head -n 1)"
    wget --no-verbose --read-timeout=30 "$LATEST_DEB_URL" -O "$BUILD_DIR"/deps/"$DEB_NAME".deb
}
# debiangetlatestdebfunc "stretch" amd64 "nodejs"
# cd "$BUILD_DIR"/deps/extracted
wget --no-verbose "https://nodejs.org/dist/v8.9.3/node-v8.9.3-linux-x64.tar.xz" -O "$BUILD_DIR"/deps/nodejs.tar.xz
cd "$BUILD_DIR"/deps
tar -xf "$BUILD_DIR"/deps/nodejs.tar.xz
mkdir "$BUILD_DIR"/discord-css-injection.AppDir/usr
cp -r "$BUILD_DIR"/deps/node-v8.9.3-linux-x64/bin "$BUILD_DIR"/discord-css-injection.AppDir/usr/bin
cp -r "$BUILD_DIR"/deps/node-v8.9.3-linux-x64/include "$BUILD_DIR"/discord-css-injection.AppDir/usr/include
cp -r "$BUILD_DIR"/deps/node-v8.9.3-linux-x64/lib "$BUILD_DIR"/discord-css-injection.AppDir/usr/lib
cp -r "$BUILD_DIR"/deps/node-v8.9.3-linux-x64/share "$BUILD_DIR"/discord-css-injection.AppDir/usr/share
chmod a+x "$BUILD_DIR"/discord-css-injection.AppDir/usr/bin/node
debextractfunc () {
    ar x "$BUILD_DIR"/deps/"$1"
    rm -f "$BUILD_DIR"/deps/extracted/control.tar.gz
    rm -f "$BUILD_DIR"/deps/extracted/debian-binary
    tar -xf "$BUILD_DIR"/deps/extracted/data.tar.* -C "$BUILD_DIR"/deps/extracted/
    rm -f "$BUILD_DIR"/deps/extracted/data.tar.*
    if [ -f "$BUILD_DIR"/deps/extracted/usr/share/doc/git/contrib/subtree/COPYING ]; then
        rm "$BUILD_DIR"/deps/extracted/usr/share/doc/git/contrib/subtree/COPYING
    fi
    if [ -f "$BUILD_DIR"/deps/extracted/usr/share/doc/git/contrib/persistent-https/LICENSE ]; then
        rm "$BUILD_DIR"/deps/extracted/usr/share/doc/git/contrib/persistent-https/LICENSE
    fi
    cp -r "$BUILD_DIR"/deps/extracted/* "$BUILD_DIR"/discord-css-injection.AppDir/
    rm -rf "$BUILD_DIR"/deps/extracted/*
}

# debextractfunc "nodejs.deb"
rm -rf "$BUILD_DIR"/deps

mkdir -p "$BUILD_DIR"/discord-css-injection.AppDir/usr/share/discord-css-injection
mkdir -p "$BUILD_DIR"/discord-css-injection.AppDir/usr/bin
cp -r "$HOME"/node_modules "$BUILD_DIR"/discord-css-injection.AppDir/usr/share/discord-css-injection/node_modules
ln -s "$BUILD_DIR"/discord-css-injection.AppDir/usr/share/discord-css-injection/node_modules/asar/bin/asar.js "$BUILD_DIR"/discord-css-injection.AppDir/usr/bin/asar
# ln -s "$BUILD_DIR"/discord-css-injection.AppDir/usr/bin/nodejs "$BUILD_DIR"/discord-css-injection.AppDir/usr/bin/node
cp ~/github/discord-css-injection/discord-css-injection.sh "$BUILD_DIR"/discord-css-injection.AppDir/usr/bin/discord-css-injection.sh
chmod a+x "$BUILD_DIR"/discord-css-injection.AppDir/usr/bin/discord-css-injection.sh
cp ~/github/AppImages/spm.png "$BUILD_DIR"/discord-css-injection.AppDir/discord-css-injection.png
cat >"$BUILD_DIR"/discord-css-injection.AppDir/discord-css-injection.desktop << EOL
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=discord-css-injection
Comment=Add CSS hotloading to Discord Canary
Exec=./usr/bin/discord-css-injection.sh
Icon=discord-css-injection
Categories=Utility;
Terminal=true

EOL

cat >"$BUILD_DIR"/discord-css-injection.AppDir/AppRun.conf << EOL
APPRUN_SET_PATH="TRUE"
APPRUN_SET_LD_LIBRARY_PATH="TRUE"
APPRUN_SET_PYTHONPATH="FALSE"
APPRUN_SET_PYTHONHOME="FALSE"
APPRUN_SET_PYTHONDONTWRITEBYTECODE="FALSE"
APPRUN_SET_XDG_DATA_DIRS="FALSE"
APPRUN_SET_PERLLIB="FALSE"
APPRUN_SET_GSETTINGS_SCHEMA_DIR="FALSE"
APPRUN_SET_QT_PLUGIN_PATH="FALSE"
APPRUN_EXEC="./usr/bin/discord-css-injection.sh"

EOL

wget "https://raw.githubusercontent.com/simoniz0r/AppImages/master/resources/AppRun" -O "$BUILD_DIR"/discord-css-injection.AppDir/AppRun
chmod a+x "$BUILD_DIR"/discord-css-injection.AppDir/AppRun

appimagetool "$BUILD_DIR"/discord-css-injection.AppDir "$BUILD_DIR"/discord-css-injection-"$VERSION"-x86_64.AppImage || exit 1
rm -rf "$BUILD_DIR"/discord-css-injection.AppDir
exit 0
