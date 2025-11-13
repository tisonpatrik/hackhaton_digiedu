FROM rust:1.90-slim-bookworm AS chef

# system deps pro build (pokud používáš openssl/postgres atd., přidej libssl-dev, pkg-config…)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      pkg-config \
      libssl-dev \
      clang \
      make \
      git \
      curl \
    && rm -rf /var/lib/apt/lists/*

RUN cargo install cargo-chef --locked
WORKDIR /app

############################
# 3) PLANNER STAGE (ANALÝZA DEPENDENCIES)
############################
FROM chef AS planner
WORKDIR /app

# když máš workspace, zkopíruj i další Cargo.toml
COPY Cargo.toml Cargo.lock ./
COPY src src

# v případě workspace:
# COPY crates ./crates
# COPY some_other_crate ./some_other_crate

RUN cargo chef prepare --recipe-path recipe.json

############################
# 4) BUILDER STAGE (CACHE DEPS + BUILD)
############################
FROM chef AS builder
WORKDIR /app

# 4.1 – nejdřív deps podle recipe → využijeme Docker cache
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

# 4.2 – teď teprve zbytek kódu (mění se častěji)
COPY . .

# pokud máš více binárek, můžeš sestavit jen jednu:
RUN cargo build --release --bin data_processing

############################
# 5) RUNTIME STAGE (MALÝ, BEZ TOOLCHAINU)
############################
FROM gcr.io/distroless/cc-debian12 AS runtime
WORKDIR /app
COPY --from=builder /app/target/release/data_processing /app/data_processing
USER 10001
EXPOSE 8080
ENTRYPOINT ["/app/data_processing"]
