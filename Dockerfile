FROM ubuntu:14.04

ENV RUBY_MAJOR 2.3
ENV RUBY_VERSION 2.3.0

RUN sed -i -- 's/archive.ubuntu.com/mirror.yandex.ru/g' /etc/apt/sources.list

ENV LAST_UPDATED 20-02-2016

#####################
#    Basic tools    #
#####################
RUN apt-get update -qq && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends sudo build-essential autoconf curl git imagemagick wget automake libtool nginx mysql-client vim-nox

RUN rm /etc/nginx/sites-enabled/default

#####################
# Node installation #
#####################

RUN curl -sL https://deb.nodesource.com/setup | sudo bash - \
  && apt-get install -y --no-install-recommends nodejs

#####################
# Ruby installation #
#####################

# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
RUN apt-get install -y --no-install-recommends bison libpq-dev libgdbm-dev ruby ruby-dev libcurl3 libcurl3-dev libffi-dev libmagickwand-dev libmysqlclient-dev libv8-dev libreadline6 libreadline6-dev \
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
