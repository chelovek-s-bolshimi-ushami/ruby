# FROM ubuntu:14.04
FROM phusion/baseimage:latest

ENV RUBY_MAJOR 2.2
ENV RUBY_VERSION 2.2.5

ENV LAST_UPDATED 08-05-2016

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

#ADD install-imagemagick /tmp/install-imagemagick
#RUN /tmp/install-imagemagick
RUN apt-get install imagemagick ghostscript

RUN mkdir /jemalloc && cd /jemalloc &&\
      wget http://www.canonware.com/download/jemalloc/jemalloc-3.6.0.tar.bz2 &&\
      tar -xjf jemalloc-3.6.0.tar.bz2 && cd jemalloc-3.6.0 && ./configure && make &&\
      mv lib/libjemalloc.so.1 /usr/lib && cd / && rm -rf /jemalloc

#####################
# Ruby installation #
#####################
# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
RUN apt-get install -y --no-install-recommends bison libgdbm-dev ruby ruby-dev libcurl3 libcurl3-dev libffi-dev libmagickwand-dev libmysqlclient-dev libv8-dev libreadline6 libreadline6-dev \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /usr/src/ruby \
  && curl -SL "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.bz2" \
  | tar -xjC /usr/src/ruby --strip-components=1 \
  && cd /usr/src/ruby \
  && autoconf \
  && ./configure --with-readline --disable-install-doc \
  && make -j"$(nproc)" \
  && make install \
  && apt-get purge -y --auto-remove bison ruby ruby-dev libgdbm-dev \
  && apt-get autoremove -y \
  && rm -r /usr/src/ruby

# skip installing gem documentation
RUN echo 'gem: --no-rdoc --no-ri' >> "$HOME/.gemrc"

# install things globally, for great justice
ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH
RUN gem install bundler \
  && bundle config --global path "$GEM_HOME" \
  && bundle config --global bin "$GEM_HOME/bin"

# don't create ".bundle" in all our apps
ENV BUNDLE_APP_CONFIG $GEM_HOME

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
