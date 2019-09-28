#!/bin/sh
apk update
apk add wget gcc libc-dev make git g++ perl linux-headers gnupg
mkdir build
cd build
wget https://nginx.org/download/nginx-1.16.1.tar.gz
wget https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz
wget https://www.zlib.net/zlib-1.2.11.tar.gz
wget https://www.openssl.org/source/openssl-1.1.1d.tar.gz
git clone https://github.com/ngchianglin/NginxContentFilter.git

nginx_sha256="f11c2a6dd1d3515736f0324857957db2de98be862461b5a542a3ac6188dbe32b"
pcre_sha256="0b8e7465dc5e98c757cc3650a20a7843ee4c3edf50aaf60bb33fd879690d2c73"
zlib_sha256="c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1"
openssl_sha256="1e3a91bc1f9dfce01af26026f856e064eab4c8ee0a8f457b5ae30b40b8b711f2"
content_filter_config="d20e9df127e9e3c87e175b7a2191021a9a3ffc0d94aff5e1dfbdbbaaea033074"
content_filter_module="ec911ea799afbe975439c157b15e2a685c46fb38c291d5f93f75bc973c3618c3"

cksum()
{
  checksum=$1
  file=$2
  val="`sha256sum $file  | cut -d ' ' -f1`"

  if [ $val != $checksum ]
  then
      echo "Sha256 sum of package $file does not match !"
      exit 1
  else
      return 0
  fi
}

cksum $nginx_sha256 "nginx-1.16.1.tar.gz"
cksum $pcre_sha256 "pcre-8.43.tar.gz"
cksum $zlib_sha256 "zlib-1.2.11.tar.gz"
cksum $openssl_sha256 "openssl-1.1.1d.tar.gz"
cksum $content_filter_config "NginxContentFilter/config"
cksum $content_filter_module "NginxContentFilter/ngx_http_ct_filter_module.c"

tar -zxvf nginx-1.16.1.tar.gz
tar -zxvf pcre-8.43.tar.gz
tar -zxvf zlib-1.2.11.tar.gz
tar -zxvf openssl-1.1.1d.tar.gz

cd nginx-1.16.1
./configure --with-cc-opt="-Wextra -Wformat -Wformat-security -Wformat-y2k -Werror=format-security -fPIE -O2 -D_FORTIFY_SOURCE=2 -fstack-protector-all" --with-ld-opt="-pie -Wl,-z,relro -Wl,-z,now -Wl,--strip-all" --with-http_v2_module --with-http_ssl_module --without-http_uwsgi_module --without-http_fastcgi_module   --without-http_scgi_module --without-http_empty_gif_module --with-openssl=../openssl-1.1.1d --with-openssl-opt="no-ssl2 no-ssl3 no-comp no-weak-ssl-ciphers -O2 -D_FORTIFY_SOURCE=2 -fstack-protector-all -fPIC" --with-zlib=../zlib-1.2.11 --with-zlib-opt="-O2 -D_FORTIFY_SOURCE=2 -fstack-protector-all -fPIC" --with-pcre=../pcre-8.43 --with-pcre-opt="-O2 -D_FORTIFY_SOURCE=2 -fstack-protector-all -fPIC" --with-pcre-jit --add-module=../NginxContentFilter
make
make install
cat << EOF > /usr/local/nginx/conf/nginx.conf
worker_processes  1;
events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay     on;
    keepalive_timeout  65;

    server {
        listen       8000;
        server_name  localhost;
        charset utf-8;

        location / {
                root   html;
                index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

    }

}

EOF

