# nginx-lua
```
FROM alpine:3.4

ENV NGINX_VERSION 1.15.8
ENV DEVEL_KIT_MODULE_VERSION 0.3.0
ENV OPENSSL_VERSION 1.0.2h

ENV LUA_JIT 2.0.5
ENV LUA_MODULE_VERSION 0.10.9
ENV LUA_RESTY_CORE 0.1.12
ENV LUA_RESTY_MYSQL 0.19
ENV LUA_RESTY_MEMCACHED 0.14
ENV LUA_JSON_LUA 0.1.1

ENV LUAJIT_LIB=/usr/local/lib/
ENV LUAJIT_INC=/usr/local/include/luajit-2.0

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# install LuaJIT
RUN apk add --no-cache \
	bash \
	openssl \
	git \
	curl \
	tar \
	make \
	autoconf \
	automake \
	patch \
	dpkg-dev \
	fakeroot \
	gcc \
	libc-dev \
	gnupg \
	libxslt-dev \
	perl \
	g++ \
	openssl-dev \
	pcre-dev \
	zlib-dev \
	linux-headers \
	gnupg \
	gd-dev \
	geoip-dev \
	perl-dev

RUN mkdir -p /usr/src \
    && curl -fSL http://luajit.org/download/LuaJIT-$LUA_JIT.tar.gz -o /tmp/luajit.tar.gz \
    && tar -xvf /tmp/luajit.tar.gz -C /tmp \
    && rm /tmp/luajit.tar.gz \
    && cd /tmp/LuaJIT-$LUA_JIT \
    && make -j2 \
    && make install \
    && rm -rf /tmp/LuaJIT-$LUA_JIT

RUN curl -fSL https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz -o openssl.tar.gz --insecure \
	&& curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
	&& curl -fSL https://github.com/simpl/ngx_devel_kit/archive/v$DEVEL_KIT_MODULE_VERSION.tar.gz -o ndk.tar.gz --insecure \
	&& curl -fSL https://github.com/openresty/lua-nginx-module/archive/v$LUA_MODULE_VERSION.tar.gz -o lua.tar.gz --insecure \
	&& curl -fSL https://github.com/openresty/lua-resty-core/archive/v$LUA_RESTY_CORE.tar.gz -o lrc.tar.gz --insecure \
	&& curl -fSL https://github.com/openresty/lua-resty-mysql/archive/v$LUA_RESTY_MYSQL.tar.gz -o lrm.tar.gz --insecure \
	&& curl -fSL https://github.com/openresty/lua-resty-memcached/archive/v$LUA_RESTY_MEMCACHED.tar.gz -o lrmd.tar.gz --insecure \
	&& curl -fSL https://github.com/rxi/json.lua/archive/v$LUA_JSON_LUA.tar.gz -o ljl.tar.gz --insecure

RUN mkdir -p /usr/src \
	&& tar -zxC /usr/src -f openssl.tar.gz \
	&& rm openssl.tar.gz \
	&& tar -zxC /usr/src -f nginx.tar.gz \
	&& rm nginx.tar.gz \
	&& tar -zxC /usr/src -f ndk.tar.gz \
	&& rm ndk.tar.gz \
	&& tar -zxC /usr/src -f lua.tar.gz \
	&& rm lua.tar.gz \
	&& tar -zxC /usr/src -f lrc.tar.gz \
	&& rm lrc.tar.gz \
	&& tar -zxC /usr/src -f lrm.tar.gz \
	&& rm lrm.tar.gz \
	&& tar -zxC /usr/src -f lrmd.tar.gz \
	&& rm lrmd.tar.gz \
	&& tar -zxC /usr/src -f ljl.tar.gz \
	&& rm ljl.tar.gz

RUN addgroup -S nginx \
	&& adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx

RUN CONFIG="\
		--prefix=/etc/nginx \
		--sbin-path=/usr/sbin/nginx \
		--modules-path=/usr/lib/nginx/modules \
		--conf-path=/etc/nginx/nginx.conf \
		--error-log-path=/var/log/nginx/error.log \
		--http-log-path=/var/log/nginx/access.log \
		--pid-path=/var/run/nginx.pid \
		--lock-path=/var/run/nginx.lock \
		--http-client-body-temp-path=/var/cache/nginx/client_temp \
		--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
		--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
		--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
		--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
		--user=nginx \
		--group=nginx \
		--with-http_ssl_module \
		--with-http_realip_module \
		--with-http_addition_module \
		--with-http_sub_module \
		--with-http_dav_module \
		--with-http_flv_module \
		--with-http_mp4_module \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_random_index_module \
		--with-http_secure_link_module \
		--with-http_stub_status_module \
		--with-http_auth_request_module \
		--with-http_xslt_module=dynamic \
		--with-http_image_filter_module=dynamic \
		--with-http_geoip_module=dynamic \
		--with-http_perl_module=dynamic \
		--with-threads \
		--with-stream \
		--with-stream_ssl_module \
		--with-http_slice_module \
		--with-stream_geoip_module=dynamic \
		--with-mail \
		--with-mail_ssl_module \
		--with-file-aio \
		--with-http_v2_module \
		--with-openssl=/usr/src/openssl-$OPENSSL_VERSION \
		--add-module=/usr/src/ngx_devel_kit-$DEVEL_KIT_MODULE_VERSION \
		--add-module=/usr/src/lua-nginx-module-$LUA_MODULE_VERSION \
	" \
	&& cd /usr/src/nginx-$NGINX_VERSION \
	&& ./configure $CONFIG --with-debug \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& mv objs/nginx objs/nginx-debug \
	&& mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
	&& mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
	&& mv objs/ngx_http_perl_module.so objs/ngx_http_perl_module-debug.so \
	&& mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so \
	&& ./configure $CONFIG

RUN cd /usr/src/nginx-$NGINX_VERSION \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& rm -rf /etc/nginx/html/ \
	&& mkdir /etc/nginx/conf.d/ \
	&& mkdir -p /usr/share/nginx/html/ \
	&& install -m644 html/index.html /usr/share/nginx/html/ \
	&& install -m644 html/50x.html /usr/share/nginx/html/ \
	&& install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
	&& install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so \
	&& install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so \
	&& install -m755 objs/ngx_http_perl_module-debug.so /usr/lib/nginx/modules/ngx_http_perl_module-debug.so \
	&& install -m755 objs/ngx_stream_geoip_module-debug.so /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so

RUN ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
	&& strip /usr/sbin/nginx* \
	&& strip /usr/lib/nginx/modules/*.so \
	&& rm -rf /usr/src/nginx-$NGINX_VERSION \
	# forward request and error logs to docker log collector
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

COPY ./src/nginx.conf /etc/nginx/nginx.conf
COPY ./src/nginx.vh.default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
```
