FROM n8nio/n8n:latest

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        python3-pip \
        curl \
    && pip3 install --no-cache-dir yt-dlp \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /data/temp && chown -R node:node /data

USER node
WORKDIR /data

ENV N8N_PORT=5678
EXPOSE 5678

CMD ["tini", "--", "n8n"]
