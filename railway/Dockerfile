# Railway-optimized OpenEMR Dockerfile
# Uses the official openemr/openemr Docker image with Railway-specific configuration

FROM openemr/openemr:7.0.3

# Copy Railway-specific entrypoint
COPY railway-entrypoint.sh /railway-entrypoint.sh
RUN chmod +x /railway-entrypoint.sh

# Railway uses PORT environment variable - default to 80
ENV PORT=80

# Expose HTTP port
EXPOSE 80 443

# Use Railway-optimized entrypoint
CMD ["/railway-entrypoint.sh"]
