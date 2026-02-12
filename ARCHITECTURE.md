# Qusto Analytics Architecture

## Overview

Qusto Analytics uses a dual-repository architecture with clear separation between open-source core (AGPL) and proprietary features.

## Repository Structure

### This Repository (qusto-analytics - Public)

**License**: AGPL-3.0  
**Branch**: `public-main` (default)

**Contains**:
- Core analytics engine (Elixir/Phoenix)
- Basic dashboard and reporting
- Event ingestion and storage
- Public API
- Community features

**Tech Stack**:
- **Backend**: Elixir 1.14+, Phoenix 1.7+
- **Database**: PostgreSQL 14+ (metadata), ClickHouse 24+ (events)
- **Frontend**: React 18, TailwindCSS
- **Deployment**: Docker, Docker Compose

### Private Repository (qusto-ecommerce)

**License**: Proprietary  
**Access**: Private

**Contains**:
- E-commerce analytics modules
- Advanced attribution engine
- AI-powered insights
- React microfrontends (Webpack Module Federation)
- Go backend microservices

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│ Qusto Analytics CE (Phoenix/Elixir)                     │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Web Layer (Phoenix)                              │  │
│  │  - Controllers                                    │  │
│  │  - LiveView components                            │  │
│  │  - API endpoints                                  │  │
│  └──────────────────────────────────────────────────┘  │
│                         │                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Business Logic                                    │  │
│  │  - Stats aggregation                              │  │
│  │  - Event processing                               │  │
│  │  - Goal tracking                                  │  │
│  └──────────────────────────────────────────────────┘  │
│                         │                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Data Layer                                        │  │
│  │  - PostgreSQL (metadata)                          │  │
│  │  - ClickHouse (events/analytics)                  │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Frontend (React)                                         │
│  - Dashboard UI                                          │
│  - Charts and visualizations                             │
│  - Settings pages                                        │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Tracking Script (<1KB JS)                               │
│  - Pageview tracking                                     │
│  - Event tracking                                        │
│  - Privacy-focused                                       │
└─────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Event Ingestion

```
Website → Tracking Script → Ingestion API → Event Pipeline → ClickHouse
                                  │
                                  └──→ Validation
                                  └──→ Enrichment
                                  └──→ Rate limiting
```

### 2. Analytics Queries

```
Dashboard → Phoenix Controller → Stats Module → ClickHouse Query → Aggregation → JSON Response
```

### 3. Goal Tracking

```
Custom Event → API → Goal Matcher → ClickHouse → Conversion Stats
```

## Database Schema

### PostgreSQL (Metadata)

- `users` - User accounts
- `sites` - Website properties
- `goals` - Conversion goals
- `invitations` - Team invitations
- `api_keys` - API authentication
- `subscriptions` - Billing (if using Qusto Cloud)

### ClickHouse (Events)

- `events` - All events (pageviews, custom events)
- `sessions` - Session aggregations
- `imported_*` - Imported historical data

**Event Schema**:
```sql
timestamp      DateTime
domain         String
pathname       String
referrer       String
referrer_source String
country_code   FixedString(2)
screen_size    String
browser        String
os             String
...
```

## Module Structure

```
lib/
├── plausible/              # Core business logic
│   ├── stats/              # Statistics calculations
│   ├── ingestion/          # Event ingestion
│   ├── auth/               # Authentication
│   ├── billing/            # Billing (CE: basic)
│   └── site/               # Site management
├── plausible_web/          # Web layer
│   ├── controllers/        # HTTP controllers
│   ├── live/               # LiveView components
│   ├── plugs/              # Middleware
│   └── templates/          # Server-side templates
└── mix.exs                 # Project configuration

assets/
├── js/                     # JavaScript
│   ├── dashboard/          # Dashboard React app
│   └── liveview/           # LiveView hooks
└── css/                    # Tailwind styles

priv/
├── repo/migrations/        # PostgreSQL migrations
└── ingest_repo/migrations/ # ClickHouse migrations
```

## Deployment Architecture

### Development (Docker Compose)

```yaml
services:
  analytics:   # Phoenix app
  postgres:    # Metadata DB
  clickhouse:  # Analytics DB
```

### Production Options

**Option 1: Single Server**
- Docker Compose on VPS
- Suitable for <100k pageviews/month

**Option 2: Kubernetes**
- Scalable horizontally
- Separate database instances
- Load balancing

**Option 3: Managed Qusto Cloud**
- Fully managed
- Auto-scaling
- EU-hosted (Hetzner Germany)

## Performance Considerations

### Caching

- Fragment caching for dashboard
- Query result caching (15 minutes)
- Rate limiting per domain

### Database Optimization

- **PostgreSQL**: B-tree indexes, connection pooling
- **ClickHouse**: Partitioned by date, materialized views for common queries

### Scaling Strategy

- Horizontal: Add more Phoenix instances
- Vertical: Scale ClickHouse cluster
- Caching: Redis for session caching

## Security

- **Authentication**: Bcrypt password hashing, session tokens
- **Authorization**: Role-based access control
- **Rate Limiting**: Per-IP and per-domain limits
- **Data Privacy**: IP anonymization, no PII stored
- **HTTPS**: Enforced in production
- **CSP**: Content Security Policy headers

## Monitoring

- **Logging**: Structured logging with Logger
- **Metrics**: Telemetry events
- **Health Checks**: `/api/health` endpoint
- **Error Tracking**: Sentry integration (optional)

## Development vs Production

### Development
- SQLite for testing (optional)
- Hot code reloading
- Detailed error pages
- No caching

### Production
- PostgreSQL + ClickHouse
- Compiled releases
- Error reporting to Sentry
- Full caching enabled
- Rate limiting strict

## Contributing to Architecture

When proposing architectural changes:
1. Open a discussion first
2. Consider backward compatibility
3. Document database migrations
4. Update this document
5. Add tests for new patterns

## Related Documentation

- [API Documentation](https://docs.qusto.io/api)
- [Self-Hosting Guide](https://docs.qusto.io/self-hosting)
- [Database Schema](https://docs.qusto.io/schema)
- [Contributing Guide](CONTRIBUTING.md)

---

For questions about architecture, open a [GitHub Discussion](https://github.com/Qusto-io/qusto-analytics/discussions).
