#!/bin/sh
apk update
apk add wget gcc libc-dev make git g++ perl linux-headers gnupg
mkdir build
cd build
wget https://nginx.org/download/nginx-1.18.0.tar.gz
wget https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz
wget https://www.zlib.net/zlib-1.2.11.tar.gz
wget https://www.openssl.org/source/openssl-1.1.1g.tar.gz
git clone https://github.com/ngchianglin/NginxContentFilter.git

nginx_sha256="4c373e7ab5bf91d34a4f11a0c9496561061ba5eee6020db272a17a7228d35f99"
pcre_sha256="aecafd4af3bd0f3935721af77b889d9024b2e01d96b58471bd91a3063fb47728"
zlib_sha256="c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1"
openssl_sha256="ddb04774f1e32f0c49751e21b67216ac87852ceb056b75209af2443400636d46"
content_filter_config="d20e9df127e9e3c87e175b7a2191021a9a3ffc0d94aff5e1dfbdbbaaea033074"
content_filter_module="69068866ee84f1b70dbdef08121773f42e18ef91bd133de39d02a2299428aed7"

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

cksum $nginx_sha256 "nginx-1.18.0.tar.gz"
cksum $pcre_sha256 "pcre-8.44.tar.gz"
cksum $zlib_sha256 "zlib-1.2.11.tar.gz"
cksum $openssl_sha256 "openssl-1.1.1g.tar.gz"
cksum $content_filter_config "NginxContentFilter/config"
cksum $content_filter_module "NginxContentFilter/ngx_http_ct_filter_module.c"

tar -zxvf nginx-1.18.0.tar.gz
tar -zxvf pcre-8.44.tar.gz
tar -zxvf zlib-1.2.11.tar.gz
tar -zxvf openssl-1.1.1g.tar.gz


#
# Take note that alpine linux uses musl as the c library  
# instead of glibc. musl at the moment doesn't
# support _FORTIFY_SOURCE and this option have no 
# effect 
#
cd nginx-1.18.0
./configure --with-cc-opt="-Wextra -Wformat -Wformat-security -Wformat-y2k -Werror=format-security -fPIE -O2 -D_FORTIFY_SOURCE=2 -fstack-protector-all" --with-ld-opt="-pie -Wl,-z,relro -Wl,-z,now -Wl,--strip-all" --with-http_v2_module --with-http_ssl_module --without-http_uwsgi_module --without-http_fastcgi_module   --without-http_scgi_module --without-http_empty_gif_module --with-openssl=../openssl-1.1.1g --with-openssl-opt="no-ssl2 no-ssl3 no-comp no-weak-ssl-ciphers -O2 -D_FORTIFY_SOURCE=2 -fstack-protector-all -fPIC" --with-zlib=../zlib-1.2.11 --with-zlib-opt="-O2 -D_FORTIFY_SOURCE=2 -fstack-protector-all -fPIC" --with-pcre=../pcre-8.44 --with-pcre-opt="-O2 -D_FORTIFY_SOURCE=2 -fstack-protector-all -fPIC" --with-pcre-jit --add-module=../NginxContentFilter
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

