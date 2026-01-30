# TN Victory YouTube Transcript Automation - Render.com Optimized
# Based on n8n with yt-dlp + ffmpeg for Whisper fallback processing

FROM n8nio/n8n:latest

# Switch to root for installations
USER root

# Detect and install system dependencies for both Alpine and Debian-based systems
RUN if command -v apk > /dev/null 2>&1; then \
        # Alpine Linux
        apk update && \
        apk add --no-cache \
            ffmpeg \
            python3 \
            py3-pip \
            curl \
            wget \
            bash \
        && rm -rf /var/cache/apk/*; \
    elif command -v apt-get > /dev/null 2>&1; then \
        # Debian/Ubuntu
        apt-get update && \
        apt-get install -y --no-install-recommends \
            ffmpeg \
            python3 \
            python3-pip \
            curl \
            wget \
            bash \
        && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*; \
    else \
        echo "Unsupported package manager"; \
        exit 1; \
    fi

# Install yt-dlp via pip (more reliable than binary download)
RUN python3 -m pip install --no-cache-dir --upgrade \
    pip \
    yt-dlp \
    && python3 -m pip cache purge

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
    CMD curl -f http://localhost:5678/healthz || exit 1

# Expose port
EXPOSE 5678

# Start command (inherited from base image)
CMD ["tini", "--", "n8n"]
