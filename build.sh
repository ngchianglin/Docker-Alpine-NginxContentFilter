#!/bin/sh
apk update
apk add wget gcc libc-dev make git g++ perl linux-headers gnupg
mkdir build
cd build
wget http://nginx.org/download/nginx-1.14.0.tar.gz
wget https://ftp.pcre.org/pub/pcre/pcre-8.42.tar.gz
wget https://www.zlib.net/zlib-1.2.11.tar.gz
wget https://www.openssl.org/source/openssl-1.1.0h.tar.gz
wget https://github.com/ngchianglin/NginxContentFilter/archive/master.zip

nginx_sha256="5d15becbf69aba1fe33f8d416d97edd95ea8919ea9ac519eff9bafebb6022cb5"
pcre_sha256="69acbc2fbdefb955d42a4c606dfde800c2885711d2979e356c0636efde9ec3b5"
zlib_sha256="c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1"
openssl_sha256="5835626cde9e99656585fc7aaa2302a73a7e1340bf8c14fd635a62c66802a517"
content_filter="c29d3cbb4f9b61e8db6d3c5f4555d18417eede1f3a7308237557d379b99b9d0b"

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

cksum $nginx_sha256 "nginx-1.14.0.tar.gz"
cksum $pcre_sha256 "pcre-8.42.tar.gz"
cksum $zlib_sha256 "zlib-1.2.11.tar.gz"
cksum $openssl_sha256 "openssl-1.1.0h.tar.gz"
cksum $content_filter "master.zip"

tar -zxvf nginx-1.14.0.tar.gz
tar -zxvf pcre-8.42.tar.gz
tar -zxvf zlib-1.2.11.tar.gz
tar -zxvf openssl-1.1.0h.tar.gz
unzip master.zip
cd nginx-1.14.0
./configure --with-cc-opt="-Wextra -Wformat -Wformat-security -Wformat-y2k -fPIE -O2 -D_FORTIFY_SOURCE=2 -fstack-protector-all" --with-ld-opt="-pie -Wl,-z,relro -Wl,-z,now -Wl,--strip-all" --with-http_v2_module --with-http_ssl_module --without-http_uwsgi_module --without-http_fastcgi_module   --without-http_scgi_module --without-http_empty_gif_module --with-openssl=../openssl-1.1.0h --with-openssl-opt="shared no-ssl2 no-ssl3 no-comp no-weak-ssl-ciphers -O2 -D_FORTIFY_SOURCE=2 -fstack-protector-all" --with-zlib=../zlib-1.2.11 --with-zlib-opt="-O2  -D_FORTIFY_SOURCE=2 -fstack-protector-all -fPIC" --with-pcre=../pcre-8.42 --with-pcre-opt="-O2 -D_FORTIFY_SOURCE=2 -fstack-protector-all -fPIC" --with-pcre-jit --add-module=../NginxContentFilter-master
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

