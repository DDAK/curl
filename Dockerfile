FROM python:3.12-slim AS build

ENV curl_version 8.5.0

WORKDIR /tmp
RUN apt-get update -y && apt-get upgrade -y

RUN apt-get -qq install -y \
  build-essential \
  wget \
  clang \ 
  libssl-dev

RUN wget https://curl.haxx.se/download/curl-${curl_version}.tar.gz
RUN tar xfvz curl-${curl_version}.tar.gz
WORKDIR /tmp/curl-${curl_version}

# for static build of curl
ENV CC clang  
ENV LDFLAGS -static
ENV PKG_CONFIG pkg-config --static 

RUN ./configure  --disable-shared --enable-static --with-ssl
RUN make -j4 V=1 LDFLAGS="-static -all-static"

#discards symbols from compiled curl image.
RUN strip src/curl

# print out some info about this, size, and to ensure it's actually fully static
# RUN ls -lah src/curl
# RUN file src/curl

# # exit with error code 1 if the executable is dynamic, not static
RUN ldd src/curl && exit 1 || true


FROM python:3.12-slim as RUN
ENV curl_version 8.5.0
COPY --from=build /tmp/curl-${curl_version}/src/curl /usr/local/bin/curl
