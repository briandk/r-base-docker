FROM danielak/latex-xenial:latest
LABEL author="Brian A. Danielak"
LABEL version="0.1"

##########################################################################
# Configure Default Locale
##########################################################################
# Set the locale for English, UTF-8
#   see:
#     - https://github.com/rstudio/rmarkdown/issues/383
#     - https://github.com/rocker-org/rocker/issues/19
#     - http://crosbymichael.com/dockerfile-best-practices-take-2.html
RUN dpkg-reconfigure locales && \
    locale-gen en_US.UTF-8 && \
    /usr/sbin/update-locale LANG=en_US.UTF-8

RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

##########################################################################
# Install wget
##########################################################################
RUN apt-get update && apt-get install --assume-yes wget

##########################################################################
# Install Pandoc - set version in ENV PANDOC_VERSION
##########################################################################

# To bump a pandoc version, just update PANDOC_VERSION. The rest are chained to it.
ENV PANDOC_VERSION 1.17.2
ENV PANDOC_PACKAGE pandoc-$PANDOC_VERSION-1-amd64.deb
ENV PANDOC_URL https://github.com/jgm/pandoc/releases/download/$PANDOC_VERSION/$PANDOC_PACKAGE

RUN mkdir pandoc && cd pandoc
RUN wget "$PANDOC_URL"
RUN dpkg --install $PANDOC_PACKAGE

##########################################################################
# Install R-related Dependencies
##########################################################################

# Add R Repository for CRAN packages
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

# install some basic stuff upon which R packages depend
RUN apt-get update && apt-get install --assume-yes \
    apache2 \
    ca-certificates \
    ccache \
    gdebi \
    git \
    libcurl4-openssl-dev \
    libmysqlclient-dev \
    libpq-dev \
    libssl-dev \
    libx11-dev \
    libxml2-dev \
    lmodern \
    mysql-client \
    wget

##########################################################################
# Build R from Source
##########################################################################

# Get Build dependencies to compile R from source
RUN apt-get update && \
    apt-get build-dep --assume-yes --no-install-recommends r-base

# Build R from source
ENV RBRANCH base/
ENV RVERSION R-latest
ENV CRANURL https://cran.rstudio.com/src/

RUN wget "$CRANURL$RBRANCH$RVERSION.tar.gz" && \
    mkdir /$RVERSION && \
    tar --strip-components 1 -zxvf $RVERSION.tar.gz  -C /$RVERSION && \
    cd /$RVERSION && \
    ./configure --enable-R-shlib && \
    make && \
    make install

##########################################################################
# App Entrypoint
##########################################################################
WORKDIR /R-files
ENTRYPOINT ["R", "--vanilla"]
