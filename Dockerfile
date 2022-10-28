FROM debian:bullseye-slim

# Thanks to postgres docker for the example
RUN set -ex; \
	if ! command -v gpg > /dev/null; then \
		apt-get update; \
		apt-get install -y --no-install-recommends \
			gnupg \
			dirmngr \
		; \
		rm -rf /var/lib/apt/lists/*; \
	fi

# explicitly set user/group IDs
RUN set -eux; \
	groupadd -r aurae --gid=4301; \
	useradd -r -g aurae --uid=4301 --home-dir=/var/lib/aurae --shell=/bin/bash aurae; \
	mkdir -p /var/lib/aurae; \
	chown -R aurae:aurae /var/lib/aurae

# grab gosu for easy step-down from root
# https://github.com/tianon/gosu/releases
ENV GOSU_VERSION 1.14
RUN set -eux; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends ca-certificates wget; \
	rm -rf /var/lib/apt/lists/*; \
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	chmod +x /usr/local/bin/gosu; \
	gosu --version; \
	gosu nobody true

# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
RUN set -eux; \
	if [ -f /etc/dpkg/dpkg.cfg.d/docker ]; then \
# if this file exists, we're likely in "debian:xxx-slim", and locales are thus being excluded so we need to remove that exclusion (since we need locales)
		grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker; \
		sed -ri '/\/usr\/share\/locale/d' /etc/dpkg/dpkg.cfg.d/docker; \
		! grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker; \
	fi; \
	apt-get update; apt-get install -y --no-install-recommends locales; rm -rf /var/lib/apt/lists/*; \
	localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libnss-wrapper \
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

RUN set -eux; \
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | gosu aurae sh -s -- -y; \
	test -x /var/lib/aurae/.cargo/bin/cargo

RUN mkdir -p /etc/aurae && \
  chown -R aurae:aurae /etc/aurae

RUN mkdir -p /var/run/aurae && \
  chown -R aurae:aurae /var/run/aurae && \
  chmod 2777 /var/run/aurae

USER aurae

ENV PATH="$PATH:/var/lib/aurae/.cargo/bin" 

COPY --chown=aurae:aurae src /src
RUN cargo update --manifest-path /src/Cargo.toml

RUN make -C /src pki config
RUN make -C /src

COPY --chown=aurae:aurae src/auraescript/examples /var/lib/aurae/examples
COPY scripts /usr/bin

USER root

RUN ln -nfs /var/lib/aurae/.cargo/bin/auraed /usr/bin/auraed
RUN ln -nfs /var/lib/aurae/.cargo/bin/auraescript /usr/bin/auraescript
