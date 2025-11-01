FROM ubuntu:22.04 AS production

ENV JUDGE0_HOMEPAGE=https://github.com/infoyouth
LABEL homepage=$JUDGE0_HOMEPAGE

ENV JUDGE0_SOURCE_CODE=https://github.com/infoyouth/judge0
LABEL source_code=$JUDGE0_SOURCE_CODE

ENV JUDGE0_MAINTAINER="Youth Innovations <info.youthinno@gmail.com>"
LABEL maintainer=$JUDGE0_MAINTAINER

# Set timezone
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install Ruby 3.2
RUN apt-get update && apt-get install -y curl gnupg2 && \
    curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash && \
    echo 'eval "$(rbenv init -)"' >> /root/.bashrc && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y --no-install-recommends \
      build-essential \
      nodejs \
      cron \
      libpq-dev \
      git \
      ruby \
      ruby-dev && \
    rm -rf /var/lib/apt/lists/* 

ENV PATH=/root/.rbenv/shims:/root/.rbenv/bin:$PATH
ENV GEM_HOME=/opt/.gem/

# Install Ruby and dependencies
RUN mkdir -p /opt/.gem && \
    echo "gem: --no-document" > /root/.gemrc && \
    gem install bundler:2.4.22 && \
    npm install -g @apiaryio/aglio@2.3.0

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
RUN groupadd -r judge0 && useradd -r -g judge0 judge0 && \
    mkdir -p /api/tmp /var/run/cron && \
    chown -R judge0:judge0 /api /opt/.gem /var/run/cron

ENV JUDGE0_VERSION=1.13.1
LABEL version=$JUDGE0_VERSION

# Switch to non-root user for better security
USER judge0

FROM production AS development

CMD ["sleep", "infinity"]
