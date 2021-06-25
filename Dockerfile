FROM golang:alpine as go

FROM mwaeckerlin/very-base as build
COPY --from=go /usr/local/go /usr/lib/go
ENV PATH "/usr/lib/go/bin:$PATH"
ENV VERSION "0.11"
ENV FILE "${VERSION}.tar.gz"
ENV SOURCE "https://github.com/perkeep/perkeep/archive/refs/tags"
WORKDIR /tmp
ADD ${SOURCE}/${FILE} .
RUN ${ALLOW_USER} ${FILE}
USER ${RUN_USER}
RUN tar xf ${FILE}
WORKDIR /tmp/perkeep-${VERSION}
RUN go run make.go
COPY --chown=${RUN_USER}:${RUN_GROUP} client-config.json /home/somebody/.config/perkeep/client-config.json
#RUN mkdir -p /home/somebody/.config/perkeep
#RUN /home/somebody/go/bin/pk put init --newkey

FROM mwaeckerlin/very-base as prepare
RUN $PKG_INSTALL bash \
    bind-tools \
    ffmpeg \
    imagemagick \
    libjpeg-turbo-utils \
    tzdata
COPY --from=build /home/somebody/go /perkeep
COPY --from=build --chown=${RUN_USER}:${RUN_GROUP} /home/somebody/.config /home/somebody/.config

FROM mwaeckerlin/very-base
USER ${RUN_USER}
ENV PATH "/perkeep/bin:$PATH"
COPY --from=prepare / /
CMD ["/perkeep/bin/perkeepd", "-listen", "0.0.0.0:3179"]
VOLUME /home/somebody/.config/perkeep
EXPOSE 3179
