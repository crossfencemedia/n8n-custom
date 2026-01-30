# TN Victory YouTube Transcript Automation - Render.com Optimized
# Based on n8n with yt-dlp + ffmpeg for Whisper fallback processing

FROM n8nio/n8n:latest

# Switch to root for installations
USER root

# Install system dependencies (optimized for Alpine Linux)
RUN apk update && \
    apk add --no-cache \
        ffmpeg \
        python3 \
        py3-pip \
        curl \
        wget \
        bash \
    && rm -rf /var/cache/apk/*

# Install yt-dlp via pip (more reliable than binary download)
RUN pip3 install --no-cache-dir --upgrade \
    yt-dlp \
    && pip3 cache purge

# Create application directories with proper permissions
RUN mkdir -p /data/temp /app/temp \
    && chown -R node:node /data /app \
    && chmod 1777 /data/temp /app/temp

# Verify installations
RUN echo "=== Dependency Verification ===" \
    && ffmpeg -version | head -3 \
    && echo "---" \
    && yt-dlp --version \
    && echo "---" \
    && python3 --version \
    && echo "=== Verification Complete ==="

# Switch back to node user for security
USER node

# Set environment variables optimized for production
ENV NODE_ENV=production \
    N8N_REINSTALL_MISSING_PACKAGES=true \
    N8N_EXECUTIONS_TIMEOUT=900 \
    N8N_EXECUTIONS_TIMEOUT_MAX=1800 \
    NODE_OPTIONS="--max_old_space_size=2048" \
    TMPDIR=/app/temp

# Health check optimized for Render.com
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget --quiet --tries=1 --spider --timeout=10 http://localhost:5678/healthz || exit 1

# Expose port
EXPOSE 5678

# Start command (inherited from base image)
CMD ["tini", "--", "n8n"]
