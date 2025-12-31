# OpenEMR Railway Deployment

Deploy [OpenEMR](https://www.open-emr.org/) on [Railway](https://railway.app) with minimal configuration.

## Quick Start

### 1. Create Railway Project

1. Go to [Railway](https://railway.app) and create a new project
2. Add a **MySQL** database from the Railway dashboard

### 2. Deploy OpenEMR

1. Create a new service from your GitHub repository
2. Set the root directory if needed (Railway will detect `railway.toml`)

### 3. Configure Environment Variables

In the OpenEMR service settings, add these variables:

| Variable | Value | Description |
|----------|-------|-------------|
| `MYSQL_HOST` | `${{MySQL.MYSQLHOST}}` | MySQL hostname (use Railway reference) |
| `MYSQL_PORT` | `${{MySQL.MYSQLPORT}}` | MySQL port |
| `MYSQL_DATABASE` | `${{MySQL.MYSQLDATABASE}}` | Database name |
| `MYSQL_USER` | `${{MySQL.MYSQLUSER}}` | MySQL username |
| `MYSQL_PASS` | `${{MySQL.MYSQLPASSWORD}}` | MySQL password |
| `MYSQL_ROOT_PASS` | `${{MySQL.MYSQLPASSWORD}}` | MySQL root password (same as MYSQL_PASS for Railway) |
| `OE_USER` | `admin` | OpenEMR admin username |
| `OE_PASS` | `<your-password>` | OpenEMR admin password |

### 4. Configure Volumes (Critical!)

**You MUST attach a volume to persist OpenEMR data across deployments.**

1. Go to OpenEMR service → Settings → Volumes
2. Add a volume with mount path: `/var/www/localhost/htdocs/openemr/sites`
3. Save and redeploy

Without this volume, OpenEMR will try to re-initialize on every restart.

### 5. Wait for Initialization

First deployment takes **5-10 minutes** as OpenEMR:
- Creates database schema
- Populates initial data
- Configures the application

Monitor progress in the deployment logs.

### 6. Access OpenEMR

Once deployed, access your OpenEMR instance at the Railway-provided URL or your custom domain.

Default credentials (if using defaults):
- Username: `admin`
- Password: `pass`

**Change these immediately after first login!**

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Railway Project                     │
│                                                      │
│  ┌──────────────┐         ┌──────────────────────┐  │
│  │    MySQL     │◄───────►│      OpenEMR         │  │
│  │   Service    │ private │      Service         │  │
│  │              │ network │                      │  │
│  │  Volume:     │         │  Volume:             │  │
│  │  /var/lib/   │         │  /var/www/.../sites  │  │
│  │  mysql       │         │                      │  │
│  └──────────────┘         └──────────────────────┘  │
│                                    │                 │
└────────────────────────────────────│─────────────────┘
                                     │ HTTPS
                                     ▼
                              Your Domain/URL
```

## Files

- `Dockerfile` - Wraps official `openemr/openemr:7.0.3` image
- `railway-entrypoint.sh` - Maps Railway env vars to OpenEMR format
- `railway.toml` - Railway deployment configuration

## Troubleshooting

### 502 Bad Gateway
OpenEMR is still initializing. Wait 5-10 minutes and check logs.

### Database Connection Errors
- Verify MySQL service is running
- Check environment variables are correctly set
- Ensure you're using Railway variable references (`${{MySQL.MYSQLHOST}}`)

### "Table already exists" on restart
The sites volume is not attached. Add a volume at `/var/www/localhost/htdocs/openemr/sites`.

### Slow Performance
Increase resources via Railway dashboard:
- OpenEMR: 2+ vCPU, 2+ GB RAM
- MySQL: 2+ vCPU, 2+ GB RAM

## Resources

- [OpenEMR Documentation](https://www.open-emr.org/wiki/)
- [OpenEMR Docker Hub](https://hub.docker.com/r/openemr/openemr)
- [Railway Documentation](https://docs.railway.app)
