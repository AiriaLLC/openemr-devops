#!/bin/sh
# Railway-optimized entrypoint for OpenEMR
# Wraps the standard openemr.sh with Railway-specific configuration
set -e

echo "======================================"
echo "OpenEMR Railway Deployment"
echo "======================================"
echo ""

# Railway-specific: Parse MySQL URL if provided via DATABASE_URL
# Railway's MySQL addon provides DATABASE_URL in the format: mysql://user:password@host:port/database
if [ -n "${DATABASE_URL}" ] && [ -z "${MYSQL_HOST}" ]; then
    echo "Parsing DATABASE_URL for MySQL configuration..."
    
    # Remove mysql:// prefix
    DB_URL_CLEAN=$(echo "${DATABASE_URL}" | sed 's|mysql://||')
    
    # Extract user (everything before the first :)
    MYSQL_USER=$(echo "${DB_URL_CLEAN}" | cut -d':' -f1)
    
    # Extract password (between first : and @)
    MYSQL_ROOT_PASS=$(echo "${DB_URL_CLEAN}" | sed 's|[^:]*:\([^@]*\)@.*|\1|')
    MYSQL_PASS="${MYSQL_ROOT_PASS}"
    
    # Extract host (between @ and the port :)
    MYSQL_HOST=$(echo "${DB_URL_CLEAN}" | sed 's|[^@]*@\([^:]*\):.*|\1|')
    
    # Extract port (between host : and /)
    MYSQL_PORT=$(echo "${DB_URL_CLEAN}" | sed 's|[^@]*@[^:]*:\([0-9]*\)/.*|\1|')
    
    # Extract database (after the /)
    MYSQL_DATABASE=$(echo "${DB_URL_CLEAN}" | sed 's|.*/||' | cut -d'?' -f1)
    
    export MYSQL_HOST MYSQL_USER MYSQL_ROOT_PASS MYSQL_PASS MYSQL_PORT MYSQL_DATABASE
    echo "MySQL Host: ${MYSQL_HOST}"
    echo "MySQL Port: ${MYSQL_PORT}"
    echo "MySQL Database: ${MYSQL_DATABASE}"
    echo "MySQL User: ${MYSQL_USER}"
fi

# Alternatively, Railway MySQL addon provides these individual variables
if [ -n "${MYSQLHOST}" ] && [ -z "${MYSQL_HOST}" ]; then
    echo "Using Railway MySQL environment variables..."
    export MYSQL_HOST="${MYSQLHOST}"
    export MYSQL_PORT="${MYSQLPORT:-3306}"
    export MYSQL_USER="${MYSQLUSER:-root}"
    export MYSQL_ROOT_PASS="${MYSQLPASSWORD}"
    export MYSQL_PASS="${MYSQLPASSWORD}"
    export MYSQL_DATABASE="${MYSQLDATABASE:-openemr}"
    echo "MySQL Host: ${MYSQL_HOST}"
    echo "MySQL Port: ${MYSQL_PORT}"
    echo "MySQL Database: ${MYSQL_DATABASE}"
fi

# Set defaults for OpenEMR admin user if not provided
export OE_USER="${OE_USER:-admin}"
export OE_PASS="${OE_PASS:-pass}"

# Ensure MYSQL_ROOT_PASS is set (required for auto-config)
if [ -z "${MYSQL_ROOT_PASS}" ] && [ -n "${MYSQL_PASS}" ]; then
    export MYSQL_ROOT_PASS="${MYSQL_PASS}"
fi

echo ""
echo "Configuration:"
echo "  MySQL Host: ${MYSQL_HOST:-not set}"
echo "  MySQL Port: ${MYSQL_PORT:-3306}"
echo "  MySQL Database: ${MYSQL_DATABASE:-openemr}"
echo "  OpenEMR Admin User: ${OE_USER}"
echo ""

if [ -z "${MYSQL_HOST}" ]; then
    echo "WARNING: MYSQL_HOST not set. OpenEMR will require manual setup."
    echo "Set DATABASE_URL or individual MySQL env vars for auto-configuration."
    echo ""
fi

# Check if we should do manual setup or auto setup
if [ "${MANUAL_SETUP}" = "yes" ]; then
    echo "MANUAL_SETUP=yes - Skipping auto-configuration"
    echo "Visit the web interface to complete setup."
    echo ""
fi

echo "======================================"
echo "Starting OpenEMR..."
echo "======================================"
echo ""
echo "Default credentials (if auto-configured):"
echo "  Username: ${OE_USER}"
echo "  Password: ${OE_PASS}"
echo ""
echo "IMPORTANT: Change these credentials immediately after login!"
echo ""

# Execute the standard OpenEMR entrypoint
cd /var/www/localhost/htdocs/openemr
exec ./openemr.sh
