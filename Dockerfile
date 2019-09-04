FROM crystallang/crystal:0.30.1

# Add src
COPY . /app

WORKDIR /app

# Install shards for caching
COPY shard.yml shard.yml
# Build application
RUN shards build --production

ENV BOB_REPO_PATH="/repos"
CMD ["/app/bin/docker-entrypoint"]
