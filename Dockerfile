FROM phusion/baseimage:latest

ENV RUBY_MAJOR 2.3
ENV RUBY_VERSION 2.3.1

ENV LAST_UPDATED 22-07-2016

RUN echo "debconf debconf/frontend select Teletype" | debconf-set-selections &&\
    echo "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) main restricted universe" > /etc/apt/sources.list &&\
    echo "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc)-updates main restricted universe" >> /etc/apt/sources.list &&\
    echo "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc)-security main restricted universe" >> /etc/apt/sources.list &&\
    apt-get update && apt-get -y install fping &&\
    sh -c "fping proxy && echo 'Acquire { Retries \"0\"; HTTP { Proxy \"http://proxy:3128\";}; };' > /etc/apt/apt.conf.d/40proxy && apt-get update || true" &&\
    apt-get -y install software-properties-common &&\
    apt-mark hold initscripts &&\
    apt-get -y upgrade &&\
    apt-get -y update &&\
    apt-get -y install build-essential git curl wget \
                       libxslt-dev libcurl4-openssl-dev \
                       libssl-dev libyaml-dev libtool \
                       libxml2-dev gawk \
                       libreadline-dev autoconf automake libtool mysql-client\
                       language-pack-en \
                       psmisc vim-nox whois &&\
    cd / &&\
    apt-get clean &&\
    locale-gen en_US ru_RU.UTF-8

ADD install-imagemagick /tmp/install-imagemagick
RUN /tmp/install-imagemagick

RUN mkdir /jemalloc && cd /jemalloc &&\
      wget http://www.canonware.com/download/jemalloc/jemalloc-3.6.0.tar.bz2 &&\
      tar -xjf jemalloc-3.6.0.tar.bz2 && cd jemalloc-3.6.0 && ./configure && make &&\
      mv lib/libjemalloc.so.1 /usr/lib && cd / && rm -rf /jemalloc

RUN echo 'gem: --no-document' >> /usr/local/etc/gemrc &&\
    mkdir /src && cd /src && git clone https://github.com/sstephenson/ruby-build.git &&\
    cd /src/ruby-build && ./install.sh &&\
    cd / && rm -rf /src/ruby-build && ruby-build 2.3.1 /usr/local

RUN gem install bundler &&\
    rm -rf /usr/local/share/ri/2.3.0/system &&\
    cd / && git clone https://github.com/SamSaffron/pups.git

# don't create ".bundle" in all our apps
ENV BUNDLE_APP_CONFIG $GEM_HOME

ENV RAILS_ENV development

ENV LANG ru_RU.UTF-8
ENV LC_CTYPE ru_RU.UTF-8
ENV LC_NUMERIC ru_RU.UTF-8
ENV LC_TIME ru_RU.UTF-8
ENV LC_COLLATE ru_RU.UTF-8
ENV LC_MONETARY ru_RU.UTF-8
ENV LC_MESSAGES ru_RU.UTF-8
ENV LC_PAPER ru_RU.UTF-8
ENV LC_NAME ru_RU.UTF-8
ENV LC_ADDRESS ru_RU.UTF-8
ENV LC_TELEPHONE ru_RU.UTF-8
ENV LC_MEASUREMENT ru_RU.UTF-8
ENV LC_IDENTIFICATION ru_RU.UTF-8
ENV LC_ALL ru_RU.UTF-8

ENV RUBY_GC_HEAP_INIT_SLOTS 600000
ENV RUBY_GC_MALLOC_LIMIT 59000000
ENV RUBY_GC_HEAP_FREE_SLOTS 100000

RUN   rm -fr /usr/share/man &&\
      rm -fr /usr/share/doc &&\
      rm -fr /usr/share/vim/vim74/tutor &&\
      rm -fr /usr/share/vim/vim74/doc &&\
      rm -fr /usr/share/vim/vim74/lang &&\
      rm -fr /usr/local/share/doc &&\
      rm -fr /usr/local/share/ruby-build &&\
      rm -fr /root/.gem &&\
      rm -fr /root/.npm &&\
      rm -fr /tmp/* &&\
      rm -fr /usr/share/vim/vim74/spell/en*
