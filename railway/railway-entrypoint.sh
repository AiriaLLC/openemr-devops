#!/bin/sh
# Railway entrypoint wrapper for OpenEMR
# This script maps Railway environment variables to OpenEMR format
# and passes through to the official openemr.sh script.
#
# IMPORTANT: For persistence across restarts, attach a Railway volume at:
#   /var/www/localhost/htdocs/openemr/sites
#
# Environment variables:
#   FORCE_FRESH_INSTALL=yes - Drop all existing tables and start fresh

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

# Handle FORCE_FRESH_INSTALL - drop all tables to start fresh
if [ "${FORCE_FRESH_INSTALL}" = "yes" ] && [ -n "${MYSQL_HOST}" ] && [ -n "${MYSQL_ROOT_PASS}" ]; then
    echo "======================================"
    echo "FORCE_FRESH_INSTALL enabled"
    echo "======================================"
    echo ""
    echo "Waiting for MySQL to be ready..."
    
    DB_USER="${MYSQL_USER:-root}"
    DB_PASS="${MYSQL_PASS:-${MYSQL_ROOT_PASS}}"
    DB_PORT="${MYSQL_PORT:-3306}"
    DB_NAME="${MYSQL_DATABASE:-openemr}"
    
    # Wait for MySQL to be ready (max 60 seconds)
    for i in $(seq 1 60); do
        if mysql -h "${MYSQL_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASS}" \
            -e "SELECT 1" "${DB_NAME}" >/dev/null 2>&1; then
            echo "MySQL is ready."
            break
        fi
        if [ $i -eq 60 ]; then
            echo "MySQL connection failed after 60 attempts. Continuing anyway..."
            break
        fi
        echo "Waiting for MySQL... ($i/60)"
        sleep 1
    done
    
    # Drop all tables in the database
    echo "Dropping all existing tables in ${DB_NAME}..."
    TABLES=$(mysql -h "${MYSQL_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASS}" \
        -N -e "SELECT GROUP_CONCAT(table_name) FROM information_schema.tables WHERE table_schema='${DB_NAME}';" 2>/dev/null || echo "")
    
    if [ -n "${TABLES}" ] && [ "${TABLES}" != "NULL" ]; then
        echo "Found tables to drop: ${TABLES}"
        mysql -h "${MYSQL_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASS}" \
            -e "SET FOREIGN_KEY_CHECKS=0; DROP TABLE IF EXISTS ${TABLES}; SET FOREIGN_KEY_CHECKS=1;" "${DB_NAME}" 2>/dev/null || true
        echo "Tables dropped successfully."
    else
        echo "No existing tables found."
    fi
    
    # Remove sqlconf.php if it exists to ensure fresh setup
    SQLCONF="/var/www/localhost/htdocs/openemr/sites/default/sqlconf.php"
    if [ -f "${SQLCONF}" ]; then
        echo "Removing existing sqlconf.php..."
        rm -f "${SQLCONF}"
    fi
    
    echo "Database cleared. OpenEMR will perform fresh installation."
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
