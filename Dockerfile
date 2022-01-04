FROM python:3.8.5-alpine3.12
ARG MAINTAINER
ARG VCS_URL
ARG VCS_REF
ARG BUILD_DATE
ARG DOCKER_IMAGE
ARG PROJECT_NAME
ARG PROJECT_URL

LABEL \
    maintainer="${MAINTAINER}" \
    org.label-schema.maintainer="${MAINTAINER}" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date=${BUILD_DATE} \
	org.label-schema.name="${PROJECT_NAME}" \
	org.label-schema.url="${PROJECT_URL}" \
	org.label-schema.vcs-url="${VCS_URL}" \
	org.label-schema.vcs-ref=${VCS_REF} \
	org.label-schema.docker.image="${DOCKER_IMAGE}" \
    org.label-schema.license=MIT

RUN apk add libxml2-dev libxslt-dev python3-dev gcc build-base
RUN pip install lxml

COPY cover2cover.py /opt/cover2cover.py
COPY source2filename.py /opt/source2filename.py
