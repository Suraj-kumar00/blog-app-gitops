# =========================
# Stage 1: Builder
# =========================

ARG RUBY_VERSION=3.2.0
FROM ruby:${RUBY_VERSION}-slim as builder

# Set Rails environment
ARG RAILS_ENV=production
ENV RAILS_ENV=${RAILS_ENV} \
    BUNDLE_DEPLOYMENT=true \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_PATH=/usr/local/bundle

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    curl \
    git \
    libpq-dev \
    libvips \
    pkg-config \
    python-is-python3 \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Node.js and Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install --no-install-recommends -y nodejs && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set working directory
WORKDIR /rails

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3 && \
    bundle clean --force && \
    rm -rf /usr/local/bundle/cache/*.gem

# Copy application code
COPY . .

# Precompile bootsnap cache
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# Precompile assets (without RAILS_MASTER_KEY)
RUN SECRET_KEY_BASE=DUMMY bundle exec rails assets:precompile && \
    rm -rf tmp/cache node_modules app/javascript app/assets/builds/**/*.js.map

# =========================
# Stage 2: Final Image
# =========================
FROM ruby:${RUBY_VERSION}-slim as app

# Set Rails environment
ARG RAILS_ENV=production
ENV RAILS_ENV=${RAILS_ENV} \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=true \
    BUNDLE_DEPLOYMENT=true \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_PATH=/usr/local/bundle

# Install minimal runtime dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    libvips \
    postgresql-client \
    tzdata \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set working directory
WORKDIR /rails

# Copy built gems and application
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /rails /rails

# Copy and configure entrypoint
COPY bin/docker-entrypoint /usr/bin/docker-entrypoint
RUN chmod +x /usr/bin/docker-entrypoint

# Entrypoint prepares the database
ENTRYPOINT ["docker-entrypoint"]

# Expose app port
EXPOSE 3000

# Default command
CMD ["./bin/rails", "server"]
