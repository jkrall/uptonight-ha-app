FROM ubuntu:noble AS build-image

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        gcc \
        gfortran \
        git \
        libhdf5-dev \
        pkg-config \
        python3-dev \
        python3-pip \
        python3-venv \
    && ln -s /usr/bin/python3 /usr/local/bin/python \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Cache-bust the source checkout when the upstream main branch advances.
ADD https://api.github.com/repos/mawinkler/uptonight/git/refs/heads/main /tmp/uptonight-main-ref.json

RUN git clone --branch main --depth=1 https://github.com/mawinkler/uptonight.git . \
    && python3 -m venv venv \
    && venv/bin/pip install --no-cache-dir -r requirements.txt \
    && venv/bin/pip install --no-cache-dir pyinstaller \
    && venv/bin/pyinstaller --recursive-copy-metadata matplotlib --collect-all dateutil --onefile main.py

FROM ubuntu:noble AS runtime-image

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build-image /app/dist/main /app/main
COPY --from=build-image /app/targets /app/targets
COPY --from=build-image /app/skyfield-data /app/skyfield-data
COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
