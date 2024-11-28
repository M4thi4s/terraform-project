FROM python:3.9-slim

# add apache bench (ab) tool
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    apache2-utils

WORKDIR /seed

COPY make-data.py .
COPY generate-votes.sh generate-votes.sh

# create POST data files with ab friendly formats
RUN python make-data.py

# seed with apache benchmark (`ab`), use TARGET_HOST and TARGET_PORT if set
CMD /seed/generate-votes.sh
