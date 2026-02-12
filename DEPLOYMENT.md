# Qusto Deployment Guide

This guide explains how to deploy Qusto Analytics in various configurations.

## Architecture Overview

Qusto uses a dual-repository architecture:

1. **qusto-analytics** (Public AGPL)
   - Core analytics engine
   - Basic dashboards and reporting
   - Open source, community edition

2. **qusto-ecommerce** (Private)
   - E-commerce analytics
   - Advanced attribution
   - Proprietary features

3. **deploy-production** (Private branch)
   - Combines both repos via git submodules
   - Docker Compose orchestration
   - Production deployment configuration

## Deployment Options

### Option 1: Community Edition Only (Public)

Deploy the open-source core without proprietary features.

```bash
# Clone public repo
git clone https://github.com/Qusto-io/qusto-analytics.git
cd qusto-analytics
git checkout public-main

# Configure
cp config/config.example.env .env
# Edit .env with your settings

# Deploy with Docker Compose
docker-compose up -d

# Or deploy manually
mix deps.get
mix ecto.setup
mix phx.server
```

**Features Available:**
- ✅ Core analytics
- ✅ Basic dashboards
- ✅ Event tracking
- ✅ Simple funnels
- ❌ E-commerce analytics
- ❌ Advanced attribution
- ❌ AI tracking

### Option 2: Full Deployment with E-commerce (Private)

Deploy with all proprietary features included.

#### Step 1: Clone with Submodules

```bash
# Clone with private access
git clone --recursive git@github.com:Qusto-io/qusto-analytics.git
cd qusto-analytics
git checkout deploy-production

# Initialize submodules (if not already done)
git submodule update --init --recursive
```

#### Step 2: Configure Environment

Create `.env` file:

```bash
# Required
SECRET_KEY_BASE=your-secret-key-base-here
BASE_URL=https://analytics.yourdomain.com
POSTGRES_PASSWORD=your-postgres-password
CLICKHOUSE_PASSWORD=your-clickhouse-password
JWT_SECRET=your-jwt-secret

# E-commerce Configuration
QUSTO_ECOMMERCE_ENABLED=true
QUSTO_ECOMMERCE_PATH=modules/qusto-ecommerce
QUSTO_ECOMMERCE_URL=http://ecommerce:8085

# Optional
ANALYTICS_PORT=8000
ECOMMERCE_PORT=8085
ECOMMERCE_FRONTEND_PORT=3001
DATABASE_POOL_SIZE=10
CLICKHOUSE_POOL_SIZE=5
LOG_LEVEL=info
```

#### Step 3: Deploy with Docker Compose

```bash
# Start all services
docker-compose -f docker-compose.deploy.yml up -d

# Check logs
docker-compose -f docker-compose.deploy.yml logs -f

# Verify services
curl http://localhost:8000/api/health  # Analytics
curl http://localhost:8085/health      # E-commerce backend
curl http://localhost:3001/health      # E-commerce frontend
```

#### Step 4: Run Migrations

```bash
# Public migrations (analytics)
docker-compose -f docker-compose.deploy.yml exec analytics mix ecto.migrate

# Private migrations (e-commerce)
docker-compose -f docker-compose.deploy.yml exec ecommerce ./migrate
```

**Features Available:**
- ✅ All CE features
- ✅ E-commerce analytics
- ✅ Advanced attribution
- ✅ AI search tracking
- ✅ Revenue tracking
- ✅ Cart abandonment

## Kubernetes Deployment

### Prerequisites

- Kubernetes cluster (1.24+)
- kubectl configured
- Helm 3+

### Deploy with Helm

```bash
# Add Qusto Helm repo (private)
helm repo add qusto https://charts.qusto.io
helm repo update

# Install CE (public charts)
helm install qusto-ce qusto/qusto-analytics \
  --namespace qusto \
  --create-namespace \
  --set ingress.enabled=true \
  --set ingress.host=analytics.yourdomain.com

# Install Enterprise (private charts)
helm install qusto-enterprise qusto/qusto-complete \
  --namespace qusto \
  --create-namespace \
  --set analytics.enabled=true \
  --set ecommerce.enabled=true \
  --set ingress.enabled=true \
  --set ingress.host=analytics.yourdomain.com \
  -f values-production.yaml
```

### Manual Kubernetes Deployment

See `k8s/` directory for manifest templates.

```bash
# Deploy public analytics
kubectl apply -f k8s/public/

# Deploy private e-commerce (requires access)
kubectl apply -f k8s/private/

# Deploy combined
kubectl apply -f k8s/deploy/
```

## Separate Services Deployment

Deploy analytics and e-commerce as independent services.

### Analytics Service

```bash
cd qusto-analytics
git checkout public-main

# Deploy to your infrastructure
docker build -t qusto-analytics:latest .
docker push your-registry/qusto-analytics:latest

# Run
docker run -d \
  -p 8000:8000 \
  -e DATABASE_URL=... \
  -e CLICKHOUSE_DATABASE_URL=... \
  your-registry/qusto-analytics:latest
```

### E-commerce Service

```bash
cd qusto-ecommerce

# Backend
docker build -t qusto-ecommerce-backend:latest ./backend
docker push your-registry/qusto-ecommerce-backend:latest

# Frontend
docker build -t qusto-ecommerce-frontend:latest ./frontend
docker push your-registry/qusto-ecommerce-frontend:latest

# Configure analytics to point to e-commerce
# QUSTO_ECOMMERCE_ENABLED=true
# QUSTO_ECOMMERCE_URL=https://ecommerce-api.yourdomain.com
```

## Branch Strategy

### qusto-analytics Branches

- **public-main**: Public CE development (default for open source)
- **deploy-production**: Production with submodules (PRIVATE, never public)
- **feature/\***: Feature branches from public-main

### qusto-ecommerce Branches

- **main**: Private development (default)
- **feature/\***: Feature branches from main

### Deployment Workflow

```
┌─────────────────────────────────────────────────────────┐
│ Development                                              │
├─────────────────────────────────────────────────────────┤
│ public-main (CE)  │  ecommerce/main (Private)           │
│                   │                                      │
│ ↓ Develop & Test  │  ↓ Develop & Test                   │
│ ↓ Merge PR        │  ↓ Merge PR                         │
│ ↓ CI/CD Tests     │  ↓ CI/CD Tests                      │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ Staging/Production                                       │
├─────────────────────────────────────────────────────────┤
│ deploy-production branch                                 │
│   ↓ Update submodule reference                          │
│   ↓ git submodule update --remote                       │
│   ↓ Test combined system                                │
│   ↓ Deploy to staging                                   │
│   ↓ Deploy to production                                │
└─────────────────────────────────────────────────────────┘
```

## Updating Deployments

### Update CE Only

```bash
cd qusto-analytics
git checkout public-main
git pull origin public-main

# Rebuild and redeploy
docker-compose up -d --build analytics
```

### Update E-commerce

```bash
cd qusto-analytics
git checkout deploy-production

# Update submodule
git submodule update --remote modules/qusto-ecommerce

# Commit new submodule reference
git add modules/qusto-ecommerce
git commit -m "chore: Update e-commerce submodule"

# Rebuild and redeploy
docker-compose -f docker-compose.deploy.yml up -d --build ecommerce ecommerce-frontend
```

### Update Both

```bash
git checkout deploy-production
git pull origin deploy-production
git submodule update --remote --recursive

# Rebuild everything
docker-compose -f docker-compose.deploy.yml up -d --build
```

## Environment Variables Reference

### Required

- `SECRET_KEY_BASE` - Phoenix secret key (generate with `mix phx.gen.secret`)
- `BASE_URL` - Public URL (e.g., https://analytics.yourdomain.com)
- `DATABASE_URL` - PostgreSQL connection string
- `CLICKHOUSE_DATABASE_URL` - ClickHouse connection string
- `POSTGRES_PASSWORD` - PostgreSQL password
- `CLICKHOUSE_PASSWORD` - ClickHouse password

### E-commerce Specific

- `QUSTO_ECOMMERCE_ENABLED` - Enable proprietary features (true/false)
- `QUSTO_ECOMMERCE_PATH` - Path to e-commerce submodule
- `QUSTO_ECOMMERCE_URL` - E-commerce backend API URL
- `JWT_SECRET` - JWT signing secret

### Optional

- `ANALYTICS_PORT` - Analytics port (default: 8000)
- `ECOMMERCE_PORT` - E-commerce backend port (default: 8085)
- `ECOMMERCE_FRONTEND_PORT` - E-commerce frontend port (default: 3001)
- `DATABASE_POOL_SIZE` - PostgreSQL pool size (default: 10)
- `CLICKHOUSE_POOL_SIZE` - ClickHouse pool size (default: 5)
- `LOG_LEVEL` - Logging level (debug/info/warn/error)
- `REDIS_URL` - Redis connection string (for caching)

## Troubleshooting

### Submodule Not Initialized

```bash
git submodule update --init --recursive
```

### Missing Proprietary Features

Check:
1. `QUSTO_ECOMMERCE_ENABLED=true` in environment
2. Submodule is initialized: `ls modules/qusto-ecommerce/`
3. Elixir modules exist: `ls modules/qusto-ecommerce/elixir-modules/`

### Port Conflicts

Modify ports in `.env`:
```
ANALYTICS_PORT=8001
ECOMMERCE_PORT=8086
ECOMMERCE_FRONTEND_PORT=3002
```

### Database Connection Issues

- Verify PostgreSQL is running: `docker-compose ps postgres`
- Check connection string format
- Ensure network connectivity

### Module Federation Not Loading

- Check frontend environment: `BACKEND_URL` and `PUBLIC_URL`
- Verify CORS settings
- Check browser console for errors

## Health Checks

```bash
# Analytics
curl http://localhost:8000/api/health

# E-commerce backend
curl http://localhost:8085/health

# E-commerce frontend
curl http://localhost:3001/health

# PostgreSQL
docker-compose exec postgres pg_isready

# ClickHouse
docker-compose exec clickhouse clickhouse-client --query "SELECT 1"
```

## Backup and Restore

### Backup

```bash
# PostgreSQL
docker-compose exec postgres pg_dump -U postgres plausible > backup.sql

# ClickHouse
docker-compose exec clickhouse clickhouse-client --query "BACKUP DATABASE plausible TO Disk('backups', 'backup.zip')"
```

### Restore

```bash
# PostgreSQL
docker-compose exec -T postgres psql -U postgres plausible < backup.sql

# ClickHouse
docker-compose exec clickhouse clickhouse-client --query "RESTORE DATABASE plausible FROM Disk('backups', 'backup.zip')"
```

## Security Checklist

- [ ] Change default passwords
- [ ] Use strong `SECRET_KEY_BASE` and `JWT_SECRET`
- [ ] Enable HTTPS/TLS
- [ ] Configure firewall rules
- [ ] Set up rate limiting
- [ ] Enable database SSL
- [ ] Regular security updates
- [ ] Monitor logs
- [ ] Set up backups

## Support

- **CE Documentation**: https://docs.qusto.io/self-hosting
- **CE Issues**: https://github.com/Qusto-io/qusto-analytics/issues
- **Enterprise Support**: support@qusto.io
- **Emergency**: emergency@qusto.io

---

For questions about deployment, open a [GitHub Discussion](https://github.com/Qusto-io/qusto-analytics/discussions) or contact support@qusto.io.
