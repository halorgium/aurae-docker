FROM rust:1-bullseye

RUN rustup component add clippy

# explicitly set user/group IDs
RUN set -eux; \
	groupadd -r aurae --gid=4301; \
	useradd -r -g aurae --uid=4301 --home-dir=/home/aurae --shell=/bin/bash aurae; \
	mkdir -p /home/aurae; \
	chown -R aurae:aurae /home/aurae

ENV LANG en_US.utf8

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		locales \
		libnss-wrapper \
		git \
		gosu \
		curl \
		xz-utils \
		ca-certificates \
		build-essential \
		protobuf-compiler \
		libdbus-1-dev \
		busybox-syslogd \
		pkg-config \
		libseccomp-dev \
		zstd \
	; \
	rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/aurae && \
  chown -R aurae:aurae /etc/aurae

RUN mkdir -p /var/run/aurae && \
  chown -R aurae:aurae /var/run/aurae && \
  chmod 2777 /var/run/aurae

RUN ln -nfs /home/aurae/.cargo/bin/auraed /usr/bin/auraed
RUN ln -nfs /home/aurae/.cargo/bin/auraescript /usr/bin/auraescript

COPY scripts /usr/bin

USER aurae

RUN git clone --depth 1 https://github.com/aurae-runtime/aurae /home/aurae/src

RUN make -C /home/aurae/src compile
RUN make -C /home/aurae/src install
RUN make -C /home/aurae/src pki config
RUN make -C /home/aurae/src clean

RUN ln -nfs /home/aurae/src/auraescript/examples /home/aurae/examples

USER root
