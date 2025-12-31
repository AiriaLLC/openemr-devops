# Railway-optimized OpenEMR Dockerfile
# Uses the official openemr/openemr Docker image with minimal Railway-specific configuration

FROM openemr/openemr:7.0.3

# Copy Railway-specific entrypoint wrapper
# Note: Railway sets root directory to /railway, so paths are relative to that
COPY railway-entrypoint.sh /railway-entrypoint.sh
RUN chmod +x /railway-entrypoint.sh

# Railway uses PORT environment variable
ENV PORT=80

# Expose HTTP port (Railway handles HTTPS termination)
EXPOSE 80

# Use Railway-optimized entrypoint
CMD ["/railway-entrypoint.sh"]
