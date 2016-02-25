FROM debian:jessie

ENV DNX_VERSION 1.0.0-beta8
ENV DNX_USER_HOME /opt/dnx

RUN apt-get -qq update && apt-get -qqy install unzip curl libicu-dev libunwind8 gettext libssl-dev libcurl3-gnutls zlib1g && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://raw.githubusercontent.com/aspnet/Home/dev/dnvminstall.sh | DNX_USER_HOME=$DNX_USER_HOME DNX_BRANCH=v$DNX_VERSION sh
RUN bash -c "source $DNX_USER_HOME/dnvm/dnvm.sh \
	&& dnvm install $DNX_VERSION -alias default -r coreclr \
	&& dnvm alias default | xargs -i ln -s $DNX_USER_HOME/runtimes/{} $DNX_USER_HOME/runtimes/default"

# Install libuv for Kestrel from source code (binary is not in wheezy and one in jessie is still too old)
# Combining this with the uninstall and purge will save us the space of the build tools in the image
RUN LIBUV_VERSION=1.4.2 \
	&& apt-get -qq update \
	&& apt-get -qqy install autoconf automake build-essential libtool \
	&& curl -sSL https://github.com/libuv/libuv/archive/v${LIBUV_VERSION}.tar.gz | tar zxfv - -C /usr/local/src \
	&& cd /usr/local/src/libuv-$LIBUV_VERSION \
	&& sh autogen.sh && ./configure && make && make install \
	&& rm -rf /usr/local/src/libuv-$LIBUV_VERSION \
	&& ldconfig \
	&& apt-get -y purge autoconf automake build-essential libtool \
	&& apt-get -y autoremove \
	&& apt-get -y clean \
	&& rm -rf /var/lib/apt/lists/*


# 设置SSH服务中终端的超时时间或不超时
RUN echo 'ClientAliveInterval 120' >> /etc/ssh/sshd_config && \
echo 'ClientAliveCountMax 3' >> /etc/ssh/sshd_config

# 设置数据卷
RUN mkdir -p /code/aspnet
VOLUME /code/aspnet
WORKDIR /code/aspnet

ENV PATH $PATH:$DNX_USER_HOME/runtimes/default/bin