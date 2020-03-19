#!/usr/bin/env bash

set -e

echo "Installing packages for development tools..." && sleep 1
apt-get -y update
apt-get install -y build-essential git flex bison gperf python ruby libfontconfig1-dev
echo

cd /etc/apt

# echo "Downloading patch to QtWebkit..." && sleep 1
# git clone https://github.com/bnordlund/phantomjs-on-rpi4.git

echo "Preparing to download Debian source package..."
apt-get -y update
echo

OPENSSL_TARGET='linux-x86_64'
if [ `getconf LONG_BIT` -eq 32 ]; then
    OPENSSL_TARGET='linux-generic32'
fi

echo "Recompiling OpenSSL for ${OPENSSL_TARGET}..." && sleep 1
git clone https://salsa.debian.org/debian/openssl.git
cd openssl
OPENSSL_FLAGS='no-idea no-mdc2 no-rc5 no-zlib no-ssl2 no-ssl3 no-ssl3-method enable-rfc3779 enable-cms'
./Configure --prefix=/usr --openssldir=/etc/ssl --libdir=lib ${OPENSSL_FLAGS} ${OPENSSL_TARGET}
make depend && make && make install
cd ..
echo

echo "Building the static version of ICU library..." && sleep 1
apt-get source icu
cd icu-63.1/source
./configure --prefix=/usr --enable-static --disable-shared
make && make install
cd /etc/apt
echo

echo "Installing additional dependencies..." && sleep 1
apt-get install -y ruby-dev libsqlite3-dev libfreetype6 libssl-dev libpng12-dev libjpeg8-dev ttf-mscorefonts-installer fontconfig chrpath libssl1.0-dev libicu-dev
#apt-get install -y clang-3.8
#update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100
#update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 100
#export CC=/usr/bin/clang
#export CXX=/usr/bin/clang++
echo

echo "Downloading PhantomJS..." && sleep 1
git clone git://github.com/ariya/phantomjs.git
cd phantomjs
git checkout 2.1.1
git submodule init
git submodule update
# Apply a patch to four files in phantomjs/src/qt/qtwebkit/
# See https://forum.qt.io/topic/101727/trying-to-build-qt-5-5-1-on-ubuntu-18-04$
# See https://codereview.qt-project.org/#/c/193548
yes | cp ../phantomjs-on-rpi4/qtwebkit/JSStringRef.cpp src/qt/qtwebkit/Source/JavaScriptCore/API/JSStringRef.cpp
yes | cp ../phantomjs-on-rpi4/qtwebkit/DateConversion.cpp src/qt/qtwebkit/Source/JavaScriptCore/runtime/DateConversion.cpp
yes | cp ../phantomjs-on-rpi4/qtwebkit/WKString.cpp src/qt/qtwebkit/Source/WebKit2/Shared/API/c/WKString.cpp
yes | cp ../phantomjs-on-rpi4/qtwebkit/TypeTraits.h src/qt/qtwebkit/Source/WTF/wtf/TypeTraits.h

echo "Compiling PhantomJS..." && sleep 1
python build.py --jobs 1 --confirm --release --qt-config="-no-pkg-config" --git-clean-qtbase --git-clean-qtwebkit
echo "Stripping the executable..." && sleep 1
strip bin/phantomjs
chmod -x bin/phantomjs
chmod 775 bin/phantomjs
echo "Copying the executable..." && sleep 1
cp bin/phantomjs /usr/bin
cp bin/phantomjs ../phantomjs-on-rpi4
phantomjs --version
echo

echo "Finished"
