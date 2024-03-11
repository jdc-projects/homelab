ARG IMAGE
ARG VERSION
FROM ${IMAGE}:${VERSION}

RUN /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
RUN apt -y install barman-cli-cloud
