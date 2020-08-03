#Docker Image for building
FROM alpine:3.12.0 as builder
COPY build.sh /root
RUN cd root &&\
    chmod 755 build.sh &&\
    ./build.sh


#Actual image to be created
FROM alpine:3.12.0
COPY --from=builder /usr/local/nginx /usr/local/nginx
RUN touch /usr/local/nginx/logs/access.log &&\
    touch /usr/local/nginx/logs/error.log &&\
    ln -sf /dev/stdout /usr/local/nginx/logs/access.log &&\
    ln -sf /dev/stderr /usr/local/nginx/logs/error.log &&\
    addgroup -g 8000 nginx &&\
    adduser -G nginx -u 8000 -D  -s /sbin/nologin nginx &&\
    mkdir /usr/local/nginx/tmp &&\
    chmod 1777 /usr/local/nginx/tmp

USER nginx
EXPOSE 8000/tcp

STOPSIGNAL SIGTERM

CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]

