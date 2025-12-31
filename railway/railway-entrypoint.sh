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

# Remove default template sqlconf.php if it exists (has wrong credentials: localhost/openemr)
# OpenEMR will create a new one with the correct Railway credentials during auto-setup
TEMPLATE_SQLCONF="/var/www/localhost/htdocs/openemr/sites/default/sqlconf.php"
if [ -f "${TEMPLATE_SQLCONF}" ]; then
    if grep -q "localhost" "${TEMPLATE_SQLCONF}" 2>/dev/null; then
        echo "Removing default template sqlconf.php (has wrong credentials: localhost)..."
        rm -f "${TEMPLATE_SQLCONF}"
        echo "Template removed. OpenEMR will create sqlconf.php with correct Railway credentials."
    fi
fi

# ============================================================
# Railway-specific: Check if database already has tables
# This prevents the "table already exists" crash on container restart
# ============================================================
SITES_DIR="/var/www/localhost/htdocs/openemr/sites/default"
SQLCONF_FILE="${SITES_DIR}/sqlconf.php"

check_database_exists() {
    if [ -z "${MYSQL_HOST}" ] || [ -z "${MYSQL_DATABASE}" ]; then
        echo "Missing MYSQL_HOST or MYSQL_DATABASE"
        return 1
    fi
    
    # Use defaults if not set
    DB_USER="${MYSQL_USER:-root}"
    DB_PASS="${MYSQL_PASS:-${MYSQL_ROOT_PASS}}"
    DB_PORT="${MYSQL_PORT:-3306}"
    
    if [ -z "${DB_PASS}" ]; then
        echo "Missing MySQL password"
        return 1
    fi
    
    # Wait for MySQL to be ready (max 30 seconds)
    echo "Checking MySQL connectivity..."
    for i in $(seq 1 30); do
        if mysql -h "${MYSQL_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASS}" \
            -e "SELECT 1" "${MYSQL_DATABASE}" >/dev/null 2>&1; then
            echo "MySQL is ready."
            break
        fi
        if [ $i -eq 30 ]; then
            echo "MySQL connection failed after 30 attempts"
            return 1
        fi
        echo "Waiting for MySQL... ($i/30)"
        sleep 1
    done
    
    # Check if the users table exists (core OpenEMR table)
    echo "Checking if database has tables..."
    TABLE_EXISTS=$(mysql -h "${MYSQL_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASS}" \
        -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${MYSQL_DATABASE}' AND table_name='users';" 2>&1)
    
    if echo "${TABLE_EXISTS}" | grep -q "^1$"; then
        echo "Found existing OpenEMR database with users table"
        return 0
    fi
    echo "No existing tables found (result: ${TABLE_EXISTS})"
    return 1
}

create_sqlconf() {
    echo "Creating sqlconf.php for existing database..."
    
    # Ensure sites directory exists
    mkdir -p "${SITES_DIR}"
    
    # Create sqlconf.php with the database credentials (matching OpenEMR's format)
    cat > "${SQLCONF_FILE}" << SQLCONF
<?php
//  OpenEMR
//  MySQL Config

global \$disable_utf8_flag;
\$disable_utf8_flag = false;

\$host   = '${MYSQL_HOST}';
\$port   = '${MYSQL_PORT:-3306}';
\$login  = '${MYSQL_USER:-root}';
\$pass   = '${MYSQL_PASS:-${MYSQL_ROOT_PASS}}';
\$dbase  = '${MYSQL_DATABASE:-openemr}';
\$db_encoding = 'utf8mb4';

\$sqlconf = array();
global \$sqlconf;
\$sqlconf["host"]= \$host;
\$sqlconf["port"] = \$port;
\$sqlconf["login"] = \$login;
\$sqlconf["pass"] = \$pass;
\$sqlconf["dbase"] = \$dbase;
\$sqlconf["db_encoding"] = \$db_encoding;

//////////////////////////
//////////////////////////
//////////////////////////
//////DO NOT TOUCH THIS///
\$config = 1; /////////////
//////////////////////////
//////////////////////////
//////////////////////////
SQLCONF

    chmod 644 "${SQLCONF_FILE}"
    chown apache:root "${SQLCONF_FILE}"
    echo "Created ${SQLCONF_FILE} with correct permissions"
}

# Check if sqlconf.php exists (indicates setup is complete)
if [ ! -f "${SQLCONF_FILE}" ]; then
    echo ""
    echo "No sqlconf.php found - checking if database is already initialized..."
    
    if check_database_exists; then
        echo ""
        echo "======================================"
        echo "EXISTING DATABASE DETECTED"
        echo "======================================"
        echo "Database '${MYSQL_DATABASE}' already contains OpenEMR tables."
        echo "Creating configuration to connect to existing database..."
        echo ""
        
        create_sqlconf
        
        # Also set EMPTY env var to prevent auto_configure from running
        export EMPTY="yes"
        
        echo "Database recovery complete. OpenEMR will use existing data."
        echo ""
    else
        echo "No existing database found - will run normal setup."
    fi
else
    echo "sqlconf.php exists - using existing configuration."
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
