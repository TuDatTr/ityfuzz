FROM rust:buster as environment
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    python3-venv libz3-dev libssl-dev clang pkg-config cmake clang \
    && rm -rf /var/lib/apt/lists/*
RUN pip3 install --upgrade pip
RUN mkdir /bins

FROM environment as builder
WORKDIR /builder

COPY Cargo.toml .
COPY rust-toolchain.toml .
COPY src ./src
COPY cli ./cli
COPY benches ./benches
COPY externals ./externals

# build offchain binary
WORKDIR /builder/cli
RUN cargo build --release
RUN cp target/release/cli /bins/cli_offchain

# build onchain binary
RUN sed -i -e 's/"cmp"/"cmp","flashloan_v2"/g' ../Cargo.toml
RUN cargo build --release
RUN cp target/release/cli /bins/cli_onchain

RUN sed -i -e 's/"deployer_is_attacker"/"print_logs"/g' ../Cargo.toml
RUN cargo build --release
RUN cp target/release/cli /bins/cli_print_logs

FROM environment
WORKDIR /app
COPY --from=builder /bins /bins

COPY ui /app/ui
RUN pip3 install -r ui/requirements.txt

COPY proxy /app/proxy
RUN pip3 install -r proxy/requirements.txt

COPY ui/start.sh .
RUN chmod +x start.sh

EXPOSE 8000

CMD ./start.sh



