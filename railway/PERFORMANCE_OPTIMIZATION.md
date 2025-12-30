# Railway Performance Optimization Guide

## Quick Action Items

Since you've upgraded your Railway plan, follow these steps to allocate more resources:

### 1. Set OpenEMR Resources (Dashboard)

1. Go to [Railway Dashboard](https://railway.app)
2. Select your project → Click **openemr** service
3. Go to **Settings** tab → **Resource Limits**
4. Set:
    - **vCPU**: **4 vCPU** (or maximum available)
    - **RAM**: **4GB** (or maximum available)
5. Click **Save** (service will redeploy)

### 2. Set MySQL Resources (Dashboard)

1. In the same project → Click **MySQL** service
2. Go to **Settings** tab → **Resource Limits**
3. Set:
    - **vCPU**: **4 vCPU** (or maximum available)
    - **RAM**: **4GB** (or maximum available)
4. Click **Save** (service will redeploy)

### 3. Verify Changes

After redeployment, check logs to confirm resources:

```bash
railway logs --service openemr
railway logs --service MySQL
```

Look for resource allocation messages in the logs.

## Current Issues Identified

From the logs, we found:

1. **MySQL Resource Constraints**

    - Currently: 2 logical CPUs, ~1GB RAM
    - This is causing performance bottlenecks

2. **MySQL Histogram Update Warnings**

    - Background histogram updates causing lock wait timeouts
    - Can be mitigated with more CPU/memory

3. **False Error Logs (Fixed)**

    - OpenEMR setup script writes progress indicators (dots/pluses) to stderr
    - Railway logs these as errors, creating hundreds of false error messages
    - **Fixed**: Updated `railway-entrypoint.sh` to redirect stderr to stdout
    - After next deployment, these will appear as info logs instead of errors

4. **Apache Configuration Warning**
    - Minor issue, but can be optimized

## Recommended Resource Allocations

### Minimum (Current Issue)

-   OpenEMR: 2 vCPU, 2GB RAM ❌ (too low)
-   MySQL: 2 vCPU, 1GB RAM ❌ (too low)

### Recommended (After Upgrade)

-   OpenEMR: **4 vCPU, 4GB RAM** ✅
-   MySQL: **4 vCPU, 4GB RAM** ✅

### High Performance (If Available)

-   OpenEMR: 8 vCPU, 8GB RAM
-   MySQL: 8 vCPU, 8GB RAM

## Additional Optimizations

### MySQL Configuration (If Accessible)

If Railway's MySQL addon allows custom configuration, consider:

```ini
# Reduce histogram update frequency
histogram_generation_max_mem_size = 20000000

# Increase lock wait timeout
innodb_lock_wait_timeout = 120

# Optimize for more memory
innodb_buffer_pool_size = 2G
innodb_log_file_size = 256M
```

**Note**: Railway's MySQL addon may not expose all configuration options. Check Railway MySQL documentation for available environment variables.

### PHP/Apache Optimization

The OpenEMR Docker image already includes optimized PHP settings:

-   `memory_limit = 512M`
-   `max_execution_time = 60`

These should be sufficient with increased resources.

## Monitoring Performance

After applying changes:

1. **Check Response Times**

    - Test page load times in the OpenEMR interface
    - Monitor for improvements

2. **Watch Railway Metrics**

    - Go to **Metrics** tab in each service
    - Monitor CPU and Memory usage
    - Should stay below 80% under normal load

3. **Review Logs**
    - Check for reduced error/warning messages
    - Look for improved query performance

## Troubleshooting

**Still slow after resource increase?**

-   Check MySQL slow query log (if accessible)
-   Review application logs for specific bottlenecks
-   Consider database query optimization
-   Check network latency between services

**Resources not applying?**

-   Verify changes were saved in dashboard
-   Wait for full redeployment (check deployment logs)
-   Confirm your Railway plan supports requested resources
-   Check Railway billing/usage limits

## Next Steps

1. ✅ Set resources via Railway dashboard (see steps above)
2. ✅ Wait for services to redeploy
3. ✅ Test performance improvements
4. ✅ Monitor metrics for 24-48 hours
5. ✅ Adjust if needed based on actual usage

---

**Need Help?**

-   [Railway Documentation](https://docs.railway.app)
-   [Railway Support](https://railway.app/help)
