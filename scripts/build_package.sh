#!/usr/bin/env bash

# This script will download Nginx from official site, compile it with HTTPv2 and openssl-1.0.2e library support
# RPM package will be build.
set -e -x

PACKAGE_ROOT=$PWD
PACKAGE_NAME=nginx

echo  "Installing prerequisites packages"
apt-get install gcc -y
apt-get install libpcre3 libpcre3-dev -y
apt-get install geoip-database libgeoip-dev libgeoip1 -y
apt-get install libxslt1-dev libxml2-dev -y
apt-get install libgd-dev -y
apt-get install ruby ruby-dev build-essential -y
gem install rake
gem install fpm


echo "Cleaning install directory"
rm -rf ${PACKAGE_ROOT}/${PACKAGE_NAME}/${PACKAGE_NAME}_tmp

#Checking for files needed and creating folders structure for package building

if [ ! -e "${PACKAGE_ROOT}/${PACKAGE_NAME}/build_config" ]; then
 echo "No build configuration file found, exiting"
 exit 1
else
    # shellcheck source=../build_config
    source "${PACKAGE_ROOT}/${PACKAGE_NAME}/build_config"
fi
if [ ! -e "${PACKAGE_ROOT}/${PACKAGE_NAME}/files" ]; then
    echo "No files directory found, exiting"
    exit 1
fi
if [ ! -e "${PACKAGE_ROOT}/${PACKAGE_NAME}/scripts" ]; then
    echo "No scripts directory found, exiting"
    exit 1
fi

TMP_DIR=${PACKAGE_ROOT}/${PACKAGE_NAME}/${PACKAGE_NAME}_tmp
UPLOAD_DIR=${TMP_DIR}/SRC
BUILD_DIR=${TMP_DIR}/BUILD

#function for catching command execution errors
function check_errors() {
    if [ "$?" -ne 0 ]; then
        echo "Command $0 failure !!!!"
        exit 1
    else
        echo "OK"
    fi
}


#function for running commands
function run_command() {
    echo "$@"
    echo "$@" >> "${PACKAGE_LOG}"
    eval "$@" 2>> "${PACKAGE_LOG}"
    check_errors
}

echo "Creating directory structure"

if [ ! -e "${TMP_DIR}"  ]; then
    run_command "mkdir -p $TMP_DIR"
fi

if [ ! -e "${UPLOAD_DIR}"  ]; then
    run_command "mkdir -p $UPLOAD_DIR"
fi

if [ ! -e "${BUILD_DIR}" ]; then
    run_command "mkdir -p $BUILD_DIR"
fi

#Uploading necessary sources

run_command "cd $UPLOAD_DIR"
run_command "wget $PACKAGE_UPLOAD_LINK"
run_command "wget $OPENSSL_UPLOAD_LINK"
#run_command "git clone $UP_CHECK_MODULE_LINK"
run_command "git clone $ADV_STATUS_MODULE_LINK"
run_command "tar -zxvf $PACKAGE_ARCHIVE_FILE"
run_command "tar -zxvf $OPENSSL_ARCHIVE_FILE"
run_command "cd $PACKAGE_APP_DIR"
#run_command "patch -p0 < ../nginx_upstream_check_module/check_1.9.2+.patch"

#Configuring package

run_command "./configure --prefix=/usr/share/nginx \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--http-client-body-temp-path=/var/lib/nginx/tmp/client_body \
--http-proxy-temp-path=/var/lib/nginx/tmp/proxy \
--modules-path=/usr/lib/nginx/modules \
--http-client-body-temp-path=/var/lib/nginx/body \
--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
--http-proxy-temp-path=/var/lib/nginx/proxy \
--http-scgi-temp-path=/var/lib/nginx/scgi \
--http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
--pid-path=/run/nginx.pid \
--lock-path=/var/lock/nginx.lock \
--user=nginx \
--group=nginx \
--with-debug \
--with-pcre-jit \
--with-http_dav_module \
--with-http_slice_module \
--with-threads \
--with-http_image_filter_module \
--with-http_xslt_module=dynamic \
--with-stream \
--with-stream_ssl_module \
--with-mail \
--with-mail_ssl_module \
--with-openssl=../${OPENSSL_APP_DIR} \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_geoip_module \
--with-http_realip_module \
--with-http_sub_module \
--with-http_addition_module \
--with-http_degradation_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_random_index_module \
--with-http_secure_link_module \
--with-http_auth_request_module \
--with-http_stub_status_module \
--with-http_flv_module \
--with-http_mp4_module \
--with-debug \
--add-module=../nginx-module-vts \
--with-cc-opt='-g -O2 -fdebug-prefix-map=/build/nginx-FIJPpj/nginx-${PACKAGE_VERSION}=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' \
--with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC'"


#--add-module=../nginx_upstream_check_module
#Compiling

run_command "make"
run_command "make DESTDIR=${BUILD_DIR} install"

#Collecting all files together for package building

run_command "cp -a ${PACKAGE_ROOT}/${PACKAGE_NAME}/files/* $BUILD_DIR"
run_command "chmod +x ${BUILD_DIR}/usr/bin/*"
run_command "chmod +x ${BUILD_DIR}/usr/sbin/*"

echo $PACKAGE_VERSION

fpm -s dir -t ${PACKAGE_TYPE} -C "${BUILD_DIR}" \
    --name "custom-${PACKAGE_NAME}" \
    --version "${PACKAGE_VERSION}" \
    --iteration "${PACKAGE_RELEASE}${PACKAGE_INFO}" \
    --epoch 1 \
    -a "${ARCH}" \
    --description "${PACKAGE_DESCRIPTION}" \
    -m "${PACKAGE_MAINTAINER}" \
    --before-install "${PACKAGE_ROOT}/${PACKAGE_NAME}/scripts/package_before_install.sh" \
    --before-remove "${PACKAGE_ROOT}/${PACKAGE_NAME}/scripts/package_before_remove.sh" \
    -d "geoip-database" \
    --provides "nginx = ${PACKAGE_VERSION}-${PACKAGE_RELEASE}" \
    --replaces "nginx" \
    -p "${PACKAGE_ROOT}/custom-${PACKAGE_NAME}-${PACKAGE_VERSION}-${PACKAGE_RELEASE}.${ARCH}.${PACKAGE_TYPE}" \
    etc run usr var lib
