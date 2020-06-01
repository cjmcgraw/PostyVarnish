FROM debian:jessie

RUN apt-get update -y && \
    apt-get install -y wget make

RUN cd /tmp && \
	wget http://varnish-cache.org/_downloads/varnish-6.2.0.tgz && \
	tar -xzf varnish-6.2.0.tgz

RUN apt-get install -y supervisor apt-transport-https curl libvarnishapi-dev pkg-config build-essential automake pkgconf python3-sphinx python3-docutils libpcre3 libpcre3-dev libtool libedit-dev libncurses5-dev libncursesw5-dev

RUN cd /tmp/varnish-6.2.0 && \
	./configure && \
	make && \
	make install && \
	cd /

RUN apt-get install -y git

RUN cd /tmp && \
    git clone -b 6.2 https://github.com/nigoroll/varnish-modules.git

RUN apt-get install -y autotools-dev autoconf

RUN cd /tmp/varnish-modules && \
    ./bootstrap && \
    ./configure && \
	make && \
	make install && \
	cd /

RUN cd /tmp && \
    git clone -b 6.2 https://github.com/nigoroll/libvmod-dynamic.git

ENV PKG_CONFIG_PATH /usr/local/lib/pkgconfig
ENV ACLOCAL_PATH /usr/local/share/aclocal

RUN cd /tmp/libvmod-dynamic && \
    ./autogen.sh && \
    ./configure && \
	make && \
	make install && \
	cd / && \
	apt-get autoremove -y pkg-config make wget && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY default.vcl /etc/varnish/

ENV VARNISH_BACKEND_HOSTNAME mlmodel
ENV VARNISH_BACKEND_PORT 8501
ENV VARNISH_TTL 10s

WORKDIR /etc/varnish

COPY docker-varnish-entrypoint /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/docker-varnish-entrypoint"]

EXPOSE 80 8443
CMD []
