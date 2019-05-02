FROM php:7.0.14-fpm

# disable interactive functions
ENV DEBIAN_FRONTEND noninteractive

#For fixed: Failed to fetch Debian Jessie-updates
RUN sed -i '/jessie-updates/d' /etc/apt/sources.list

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		alien \
		binutils-dev \
		ccache \
		cdbs \
		cmake \
		debhelper \
		devscripts \
		doxygen \
		equivs \
		fakeroot \
		gdb \
		gdebi-core \
		gnupg \
		libpcre3-dev \
		gcc \
		make \
		libreadline-dev \
		libyaml-dev \
		re2c \
		rpm \
		imagemagick \
		libmagickwand-dev \
		ghostscript \
		sudo \
		wget \
		zlib1g-dev \
		curl \
		iputils-ping \
		libicu-dev \
		libmemcached-dev \
		libz-dev \
		libpq-dev \
		libjpeg-dev \
		libpng-dev \
		libfreetype6-dev \
		libssl-dev \
		libmcrypt-dev \
		libxml2-dev \
		libbz2-dev \
		git \
		locales \
    	gettext \
		zip \
		unzip \
	&& rm -rf /var/lib/apt/lists/*

# Reconfigure locales
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
		&& echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen \
		&& locale-gen

# Install PHP extensions
RUN docker-php-ext-configure gd \
    	--enable-gd-native-ttf \
    	--with-jpeg-dir=/usr/lib \
    	--with-freetype-dir=/usr/include/freetype2 \
	&& pecl install imagick && docker-php-ext-enable imagick \
	&& curl -L -o /tmp/memcached.tar.gz "https://github.com/php-memcached-dev/php-memcached/archive/php7.tar.gz" \
		&& mkdir -p memcached \
	 	&& tar -C memcached -zxvf /tmp/memcached.tar.gz --strip 1 \
		&& ( \
			cd memcached \
			&& phpize \
			&& ./configure \
			&& make -j$(nproc) \
			&& make install \
		) \
		&& rm -r memcached \
		&& rm /tmp/memcached.tar.gz \
	&& docker-php-ext-enable memcached

# Set timezone
RUN rm /etc/localtime && \
	ln -s /usr/share/zoneinfo/Europe/Kiev /etc/localtime && \
	date

# Composer
ENV COMPOSER_HOME /var/www/.composer
RUN curl -sS https://getcomposer.org/installer | php -- \
	    --install-dir=/usr/bin \
	    --filename=composer

RUN docker-php-ext-install \
		gd \
		ctype \
		dom \
		exif \
		fileinfo \
		calendar \
		ftp \
		gettext \
		iconv \
		json \
		mbstring \
		mcrypt \
		pdo \
		posix \
		shmop \
		simplexml \
		sockets \
		sysvmsg \
		sysvsem \
		sysvshm \
		tokenizer \
		xml \
		xmlwriter \
		zip \
		mysqli \
		pdo_mysql \
		wddx \
		bcmath \
		pcntl \ 
		opcache \
	&& docker-php-ext-enable \
		gd \
		ctype \
		dom \
		exif \
		fileinfo \
		ftp \
		gettext \
		iconv \
		json \
		mbstring \
		mcrypt \
		pdo \
		posix \
		shmop \
		simplexml \
		sockets \
		sysvmsg \
		sysvsem \
		sysvshm \
		tokenizer \
		xml \
		xmlwriter \
		zip \
		mysqli \
		pdo_mysql \
		wddx \
		bcmath \
		pcntl \ 
		opcache

ARG PHALCON_VERSION=3.0.3
ARG PHALCON_EXT_PATH=php7/64bits

RUN set -xe && \
        # Compile Phalcon
        curl -LO https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz && \
        tar xzf ${PWD}/v${PHALCON_VERSION}.tar.gz && \
        docker-php-ext-install -j $(getconf _NPROCESSORS_ONLN) ${PWD}/cphalcon-${PHALCON_VERSION}/build/${PHALCON_EXT_PATH} && \
        # Remove all temp files
        rm -r \
        	${PWD}/v${PHALCON_VERSION}.tar.gz \
            ${PWD}/cphalcon-${PHALCON_VERSION}

# Clear
RUN apt-get autoremove -y \
	&& apt-get clean -y \
	&& rm -rf /tmp/* /var/tmp/* \
	&& find /var/cache/apt/archives /var/lib/apt/lists -not -name lock -type f -delete \
	&& find /var/cache -type f -delete

RUN mkdir -p /var/www/api-html && chown www-data:www-data /var/www/api-html && chmod 777 /var/www/api-html

VOLUME /var/www/api-html
WORKDIR /var/www/api-html