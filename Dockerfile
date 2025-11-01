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

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg2 \
    build-essential \
    cron \
    libpq-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# Add NodeJS repository and install
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Ruby from official Ubuntu repositories
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ruby \
    ruby-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up Ruby environment
ENV GEM_HOME=/opt/.gem
ENV BUNDLE_PATH=$GEM_HOME
ENV PATH=$GEM_HOME/bin:$PATH
ENV BUNDLE_SILENCE_ROOT_WARNING=1

# Install Ruby dependencies
RUN mkdir -p $GEM_HOME && \
    echo "gem: --no-document" > /root/.gemrc && \
    gem install bundler:2.4.22 && \
    npm install -g aglio@2.3.0

EXPOSE 2358

# Create non-root user and set up permissions
RUN groupadd -r judge0 && useradd -r -g judge0 judge0 && \
    mkdir -p /api/tmp /var/run/cron && \
    chown -R judge0:judge0 /opt/.gem /var/run/cron

WORKDIR /api

COPY --chown=judge0:judge0 Gemfile* ./
RUN RAILS_ENV=production bundle

COPY --chown=judge0:judge0 cron /etc/cron.d
RUN cat /etc/cron.d/* | crontab -

COPY --chown=judge0:judge0 . .
RUN chown -R judge0:judge0 /api

ENV JUDGE0_VERSION=1.13.1
LABEL version=$JUDGE0_VERSION

# Switch to non-root user for better security
USER judge0

ENTRYPOINT ["/api/docker-entrypoint.sh"]
CMD ["/api/scripts/server"]

FROM production AS development

CMD ["sleep", "infinity"]
