FROM alpine:3.15.0 AS build

RUN apk add --no-cache build-base=0.5-r2 \
					   wget=1.21.2-r2\
					   expat-dev=2.4.1-r0 \
					   expat-static=2.4.1-r0 \
					   openssl-dev=1.1.1l-r8 \
					   openssl-libs-static=1.1.1l-r8 && \ 
	wget https://www.nlnetlabs.nl/downloads/unbound/unbound-1.14.0.tar.gz && \
    tar xzf unbound-1.14.0.tar.gz

RUN	cd unbound-1.14.0 && \
	./configure --enable-fully-static --disable-flto && \
	make && \ 
	make install && \
	strip /usr/local/sbin/unbound

RUN unbound-anchor -4; exit 0

FROM scratch

COPY --from=build /etc/passwd /etc/group /etc/
COPY --from=build /usr/local/sbin/unbound /usr/local/sbin/unbound
COPY --from=build --chown=nobody:nogroup /usr/local/etc/unbound /usr/local/etc/unbound
COPY --from=build --chown=nobody:nogroup /usr/local/etc/unbound/root.key /usr/local/etc/unbound/
COPY --chown=nobody:nogroup unbound.conf a-records.conf /usr/local/etc/unbound/

USER nobody

EXPOSE 53/tcp

CMD ["unbound"]