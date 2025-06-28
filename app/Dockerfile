FROM python:3.11-alpine

# Build arguments for cache busting and version info
ARG BUILD_DATE
ARG GIT_COMMIT

WORKDIR /app

RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Add build info to a file for debugging
RUN echo "Build Date: $BUILD_DATE" > /app/build-info.txt && \
    echo "Git Commit: $GIT_COMMIT" >> /app/build-info.txt && \
    echo "Build Timestamp: $(date)" >> /app/build-info.txt

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "30", "app:app"]
