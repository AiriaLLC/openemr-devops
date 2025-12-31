#!/bin/sh
# Railway entrypoint wrapper for OpenEMR
# This script maps Railway environment variables to OpenEMR format
# and passes through to the official openemr.sh script.
#
# IMPORTANT: This script does NOT manage sqlconf.php or detect databases.
# The official openemr.sh handles all setup logic based on the $config 
# variable in sqlconf.php. Persistence is handled by Railway volumes.

set -e

echo "======================================"
echo "OpenEMR Railway Deployment"
echo "======================================"
echo ""

# Railway MySQL addon may provide DATABASE_URL - parse it if individual vars aren't set
if [ -n "${DATABASE_URL}" ] && [ -z "${MYSQL_HOST}" ]; then
    echo "Parsing DATABASE_URL for MySQL configuration..."
    
    # Remove mysql:// prefix
    DB_URL_CLEAN=$(echo "${DATABASE_URL}" | sed 's|mysql://||')
    
    # Extract components
    MYSQL_USER=$(echo "${DB_URL_CLEAN}" | cut -d':' -f1)
    MYSQL_PASS=$(echo "${DB_URL_CLEAN}" | sed 's|[^:]*:\([^@]*\)@.*|\1|')
    MYSQL_ROOT_PASS="${MYSQL_PASS}"
    MYSQL_HOST=$(echo "${DB_URL_CLEAN}" | sed 's|[^@]*@\([^:]*\):.*|\1|')
    MYSQL_PORT=$(echo "${DB_URL_CLEAN}" | sed 's|[^@]*@[^:]*:\([0-9]*\)/.*|\1|')
    MYSQL_DATABASE=$(echo "${DB_URL_CLEAN}" | sed 's|.*/||' | cut -d'?' -f1)
    
    export MYSQL_HOST MYSQL_USER MYSQL_ROOT_PASS MYSQL_PASS MYSQL_PORT MYSQL_DATABASE
fi

# Railway MySQL addon may also provide MYSQL* variables directly
if [ -n "${MYSQLHOST}" ] && [ -z "${MYSQL_HOST}" ]; then
    echo "Using Railway MYSQL* environment variables..."
    export MYSQL_HOST="${MYSQLHOST}"
    export MYSQL_PORT="${MYSQLPORT:-3306}"
    export MYSQL_USER="${MYSQLUSER:-root}"
    export MYSQL_ROOT_PASS="${MYSQLPASSWORD}"
    export MYSQL_PASS="${MYSQLPASSWORD}"
    export MYSQL_DATABASE="${MYSQLDATABASE:-openemr}"
fi

# Set defaults for OpenEMR admin if not provided
export OE_USER="${OE_USER:-admin}"
export OE_PASS="${OE_PASS:-pass}"

# Ensure MYSQL_ROOT_PASS is set (required by OpenEMR auto-setup)
if [ -z "${MYSQL_ROOT_PASS}" ] && [ -n "${MYSQL_PASS}" ]; then
    export MYSQL_ROOT_PASS="${MYSQL_PASS}"
fi

echo "Configuration:"
echo "  MySQL Host: ${MYSQL_HOST:-not set}"
echo "  MySQL Port: ${MYSQL_PORT:-3306}"
echo "  MySQL Database: ${MYSQL_DATABASE:-openemr}"
echo "  MySQL User: ${MYSQL_USER:-not set}"
echo "  OpenEMR Admin: ${OE_USER}"
echo ""

if [ -z "${MYSQL_HOST}" ]; then
    echo "WARNING: MYSQL_HOST not set!"
    echo "OpenEMR requires a MySQL database connection."
    echo ""
fi

if [ -z "${MYSQL_ROOT_PASS}" ]; then
    echo "WARNING: MYSQL_ROOT_PASS not set!"
    echo "Auto-configuration requires MYSQL_ROOT_PASS."
    echo ""
fi

echo "======================================"
echo "Starting OpenEMR..."
echo "======================================"
echo ""
echo "First boot will take 5-10 minutes for database initialization."
echo "Default credentials: ${OE_USER} / ${OE_PASS}"
echo "IMPORTANT: Change these credentials after first login!"
echo ""

# Execute the official OpenEMR entrypoint
cd /var/www/localhost/htdocs/openemr
exec ./openemr.sh
