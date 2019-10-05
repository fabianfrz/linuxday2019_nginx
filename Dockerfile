FROM archlinux/base

# keyring verify is broken in this image
RUN sed -i -E "s/(SigLevel\s*=)(.*)/\1 Never/g" /etc/pacman.conf
RUN pacman-key --init; pacman-key --populate archlinux
RUN pacman -Syu --noconfirm
RUN pacman -S --noconfirm  geoip clang tar git make which

RUN mkdir -p /tmp/nginx
WORKDIR /tmp/nginx
# download nginx
RUN curl -o nginx.tar.gz https://nginx.org/download/nginx-1.17.4.tar.gz && tar -xzf nginx.tar.gz
# brotli
RUN git clone https://github.com/google/ngx_brotli.git; cd ngx_brotli; git submodule update --init
# WAF (naxsi)
RUN git clone https://github.com/nbs-system/naxsi.git
# traffic statistic
RUN git clone https://github.com/vozlt/nginx-module-vts.git
# nginx javascript runtime (engine script) - note that master is currently broken
RUN git clone https://github.com/nginx/njs.git; cd njs; git checkout 0.3.5

# maybe remove with-debug
RUN cd nginx-1.17.4; ./configure \
    --add-module=../naxsi/naxsi_src \
    --conf-path=/etc/nginx/nginx.conf \
    --sbin-path=/usr/bin/nginx \
    --pid-path=/run/nginx.pid \
    --lock-path=/run/lock/nginx.lock \
    --user=http \
    --group=http \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=stderr \
    --http-client-body-temp-path=/var/lib/nginx/client-body \
    --http-proxy-temp-path=/var/lib/nginx/proxy \
    --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
    --http-scgi-temp-path=/var/lib/nginx/scgi \
    --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
    --with-cc-opt='-march=x86-64 -mtune=generic -O2 -pipe -fstack-protector-strong -fno-plt -D_FORTIFY_SOURCE=2' \
    --with-ld-opt=-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now \
    --with-compat \
    --with-debug \
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module --with-http_degradation_module \
    --with-http_flv_module \
    --with-http_geoip_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_mp4_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-pcre-jit \
    --with-stream \
    --with-stream_geoip_module \
    --with-stream_realip_module \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-threads \
    --with-cc=clang \
    --add-dynamic-module=../njs/nginx/ \
    --add-dynamic-module=../nginx-module-vts/ \
    --add-dynamic-module=../ngx_brotli \
    && make && make install
 
# expose http and https port
EXPOSE 8080
EXPOSE 8443

CMD /usr/bin/nginx

