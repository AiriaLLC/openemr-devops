# Railway Resource Configuration Guide

## Setting Resource Limits

Railway manages CPU and memory limits through the dashboard UI, not through configuration files. Follow these steps to allocate more resources to your services:

### Step 1: Access Railway Dashboard

1. Go to [Railway Dashboard](https://railway.app)
2. Select your project (`openemr-demo`)
3. You'll see your services: `openemr` and `MySQL`

### Step 2: Configure OpenEMR Service Resources

1. Click on the **openemr** service
2. Go to the **Settings** tab
3. Scroll to **Resource Limits** section
4. Adjust the sliders:
    - **vCPU**: Set to **4 vCPU** (or higher if available)
    - **RAM**: Set to **4GB** (or higher if available)
5. Click **Save** - Railway will redeploy with new resources

### Step 3: Configure MySQL Service Resources

1. Click on the **MySQL** service
2. Go to the **Settings** tab
3. Scroll to **Resource Limits** section
4. Adjust the sliders:
    - **vCPU**: Set to **4 vCPU** (or higher if available)
    - **RAM**: Set to **4GB** (or higher if available)
5. Click **Save** - Railway will redeploy with new resources

### Recommended Resource Allocations

#### Minimum (Basic Usage)

-   **OpenEMR**: 2 vCPU, 2GB RAM
-   **MySQL**: 2 vCPU, 2GB RAM

#### Recommended (Production/Demo)

-   **OpenEMR**: 4 vCPU, 4GB RAM
-   **MySQL**: 4 vCPU, 4GB RAM

#### High Performance (Heavy Usage)

-   **OpenEMR**: 8 vCPU, 8GB RAM
-   **MySQL**: 8 vCPU, 8GB RAM

### Additional Performance Optimizations

#### Enable Horizontal Scaling (Optional)

If you have multiple replicas configured:

1. Go to **Settings** > **Scaling**
2. Set **Replicas** to **2-3** (for redundancy)
3. **Note**: OpenEMR requires proper session handling for multiple replicas

#### Monitor Resource Usage

After setting limits, monitor usage:

1. Go to **Metrics** tab in each service
2. Watch CPU and Memory usage graphs
3. Adjust limits if you see consistent high usage (>80%)

### Troubleshooting

**Resources not applying?**

-   Ensure you've saved the changes
-   Wait for the service to redeploy (check deployment logs)
-   Verify your Railway plan supports the requested resources

**Still experiencing slowness?**

-   Check MySQL slow query log
-   Review application logs for errors
-   Consider database query optimization
-   Check network latency between services

### Railway CLI Alternative

While Railway CLI doesn't directly support resource limits, you can verify current settings:

```bash
railway status
railway logs
```

For resource changes, use the dashboard UI as described above.
