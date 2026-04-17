# Experimental NVIDIA GPU image for transcription-server.
#
# This intentionally does NOT replace the default CPU image path.
# The upstream hwdsl2/whisper-server image currently validates cpu-only startup,
# so this variant uses an NVIDIA CUDA runtime base and the same server code with
# a patched run.sh that allows WHISPER_DEVICE=cuda.

FROM nvidia/cuda:12.3.2-cudnn9-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    TMPDIR="/run/whisper-temp"

WORKDIR /opt/src

RUN set -x \
    && mkdir -p /var/lib/whisper /run/whisper-temp \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
         ca-certificates \
         curl \
         python3 \
         python3-venv \
         python3-pip \
    && python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/venv/bin/pip install --no-cache-dir \
         faster-whisper \
         fastapi \
         "uvicorn[standard]" \
         python-multipart \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

COPY ./docker/nvidia/run.sh /opt/src/run.sh
COPY ./docker/nvidia/manage.sh /opt/src/manage.sh
COPY ./docker/nvidia/api_server.py /opt/src/api_server.py
COPY ./LICENSE /opt/src/LICENSE
RUN chmod 755 /opt/src/run.sh /opt/src/manage.sh \
    && ln -s /opt/src/manage.sh /usr/local/bin/whisper_manage

EXPOSE 9000/tcp
VOLUME ["/var/lib/whisper"]
CMD ["/opt/src/run.sh"]
