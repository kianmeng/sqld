# install dependencies
FROM rust:slim-bullseye AS compiler
RUN apt update && apt install -y libclang-dev clang \
    build-essential tcl protobuf-compiler file
RUN cargo install cargo-chef
WORKDIR /sqld

# prepare recipe
FROM compiler AS planner
COPY . .
RUN cargo chef prepare --bin sqld --recipe-path recipe.json

# build sqld
FROM compiler AS builder
COPY --from=planner sqld/recipe.json recipe.json
RUN cargo chef cook --release --bin sqld --recipe-path recipe.json
COPY . .
RUN cargo build -p sqld --release

# runtime
FROM debian:bullseye-slim
COPY --from=builder /sqld/target/release/sqld /bin/sqld
COPY docker-entrypoint.sh /usr/local/bin
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 5001 5432 8080
CMD ["/bin/sqld"]
