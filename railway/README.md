# OpenEMR Railway Deployment

This directory contains configuration files optimized for deploying OpenEMR on [Railway](https://railway.app).

## Quick Start

### 1. Create a Railway Project

1. Go to [Railway](https://railway.app) and create a new project
2. Add a **MySQL** database service from the Railway dashboard
3. Deploy from this GitHub repository

### 2. Configure Environment Variables

Railway will automatically provide MySQL connection variables. Additionally, you should set:

| Variable | Description | Default |
|----------|-------------|---------|
| `OE_USER` | OpenEMR admin username | `admin` |
| `OE_PASS` | OpenEMR admin password | `pass` |
| `MANUAL_SETUP` | Set to `yes` to skip auto-configuration | - |

### 3. Deploy

Railway will automatically build and deploy using the `railway/Dockerfile`.

**Important**: The first deployment takes 5-10 minutes as OpenEMR initializes the database schema and configuration.

## How It Works

This deployment uses the official `openemr/openemr:7.0.3` Docker image with a custom entrypoint that:

1. **Parses Railway's MySQL environment variables** - Automatically configures database connection
2. **Handles auto-configuration** - Sets up OpenEMR database schema on first boot
3. **Starts Apache** - Serves the OpenEMR application

## Environment Variables

### Automatic (from Railway MySQL)

Railway's MySQL addon provides these variables automatically:
- `DATABASE_URL` - Full MySQL connection string
- `MYSQLHOST`, `MYSQLPORT`, `MYSQLDATABASE`, `MYSQLUSER`, `MYSQLPASSWORD`

### Manual Configuration

If using an external MySQL database:

| Variable | Description | Required |
|----------|-------------|----------|
| `MYSQL_HOST` | MySQL hostname | Yes |
| `MYSQL_PORT` | MySQL port | No (default: 3306) |
| `MYSQL_DATABASE` | Database name | No (default: openemr) |
| `MYSQL_USER` | MySQL user | No (default: openemr) |
| `MYSQL_PASS` | MySQL password | Yes |
| `MYSQL_ROOT_PASS` | MySQL root password | Yes (for auto-setup) |

## Post-Deployment

1. **Access OpenEMR** at your Railway-provided URL
2. **Login** with the credentials you configured (default: admin/pass)
3. **Change the default password immediately**
4. **Configure** OpenEMR settings via Administration menu

## Troubleshooting

### Deployment Takes Too Long
OpenEMR's first boot involves database initialization which can take 5-10 minutes. Check the deployment logs for progress.

### 502 Bad Gateway
If you see this error during deployment, wait a few minutes. OpenEMR is likely still initializing.

### Database Connection Errors
Ensure Railway's MySQL service is running and the environment variables are properly linked.

## Files

- `Dockerfile` - Railway-optimized Docker configuration
- `railway-entrypoint.sh` - Custom entrypoint for Railway environment
- `railway.toml` - Railway deployment configuration

## Support

- [OpenEMR Documentation](https://www.open-emr.org/wiki/index.php/OpenEMR_Wiki_Home_Page)
- [OpenEMR Forum](https://community.open-emr.org/)
- [Railway Documentation](https://docs.railway.app)

