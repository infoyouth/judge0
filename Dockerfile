FROM judge0/compilers:1.6.0-extra AS production

ENV JUDGE0_HOMEPAGE=https://github.com/infoyouth
LABEL homepage=$JUDGE0_HOMEPAGE

ENV JUDGE0_SOURCE_CODE=https://github.com/infoyouth/judge0
LABEL source_code=$JUDGE0_SOURCE_CODE

ENV JUDGE0_MAINTAINER="Youth Innovations <info.youthinno@gmail.com>"
LABEL maintainer=$JUDGE0_MAINTAINER

ENV PATH=/usr/local/ruby-2.7.0/bin:/opt/.gem/bin:$PATH
ENV GEM_HOME=/opt/.gem/

# Set up environment and install dependencies
RUN echo "deb http://archive.debian.org/debian/ buster main" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security/ buster/updates main" >> /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until && \
    mkdir -p /opt/.gem && \
    apt-get -o Acquire::Check-Valid-Until=false update && \
    apt-get install -y --no-install-recommends \
      cron \
      libpq-dev && \
    rm -rf /var/lib/apt/lists/* && \
    echo "gem: --no-document" > /root/.gemrc && \
    gem install bundler:2.1.4 && \
    npm install -g --unsafe-perm aglio@2.3.0

EXPOSE 2358

WORKDIR /api

COPY Gemfile* ./
RUN RAILS_ENV=production bundle

COPY cron /etc/cron.d
RUN cat /etc/cron.d/* | crontab -

COPY . .

ENTRYPOINT ["/api/docker-entrypoint.sh"]
CMD ["/api/scripts/server"]

# Create non-root user and set up permissions
RUN useradd -u 1000 -m -r judge0 && \
    mkdir -p /api/tmp && \
    chown -R judge0:judge0 /api /opt/.gem

USER judge0

ENV JUDGE0_VERSION=1.13.1
LABEL version=$JUDGE0_VERSION


FROM production AS development

CMD ["sleep", "infinity"]
