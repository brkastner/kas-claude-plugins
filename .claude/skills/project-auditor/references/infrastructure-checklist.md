# Infrastructure Checklist

DevOps, CI/CD, and deployment readiness requirements.

## Developer Tooling

### Code Quality Tools

| Tool | Purpose | Config Files |
|------|---------|--------------|
| ESLint | JS/TS linting | `.eslintrc.*`, `eslint.config.mjs` |
| Prettier | Code formatting | `.prettierrc`, `prettier.config.js` |
| Ruff | Python linting + formatting | `pyproject.toml [tool.ruff]` |
| Black | Python formatting | `pyproject.toml [tool.black]` |
| MyPy | Python type checking | `pyproject.toml [tool.mypy]` |
| TypeScript | TS compilation + type check | `tsconfig.json` |

### Minimum Tooling Requirements

**JavaScript/TypeScript:**
```json
// package.json scripts
{
  "scripts": {
    "lint": "eslint . --ext .ts,.tsx",
    "lint:fix": "eslint . --ext .ts,.tsx --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "typecheck": "tsc --noEmit",
    "test": "vitest",
    "build": "next build"
  }
}
```

**Python:**
```toml
# pyproject.toml
[tool.ruff]
line-length = 100
select = ["E", "F", "I", "UP", "B"]

[tool.ruff.format]
quote-style = "double"

[tool.mypy]
strict = true
python_version = "3.12"

[tool.pytest.ini_options]
asyncio_mode = "auto"
```

### Pre-commit Hooks

**Recommended setup:**
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.3.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.8.0
    hooks:
      - id: mypy
```

**Alternative: Husky (JS/TS)**
```json
// package.json
{
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged"
    }
  },
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md}": "prettier --write"
  }
}
```

---

## CI/CD Pipeline

### Minimum CI Requirements

| Stage | Purpose | Required |
|-------|---------|----------|
| Install | Install dependencies | Yes |
| Lint | Check code style | Yes |
| Type Check | Verify types | Yes |
| Test | Run test suite | Yes |
| Build | Verify build works | Yes |
| Security Scan | Check dependencies | Recommended |

### GitHub Actions Template

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run format:check
      - run: npm run typecheck

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run test

  build:
    runs-on: ubuntu-latest
    needs: [lint, test]
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run build

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm audit --audit-level=high
```

### Python CI Template

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv python install 3.12
      - run: uv sync
      - run: uv run ruff check .
      - run: uv run ruff format --check .
      - run: uv run mypy .

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv python install 3.12
      - run: uv sync
      - run: uv run pytest

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv python install 3.12
      - run: uv pip install pip-audit
      - run: pip-audit
```

---

## Containerization

### Dockerfile Requirements

| Check | Why It Matters |
|-------|----------------|
| Multi-stage build | Smaller production image |
| Non-root user | Security best practice |
| .dockerignore | Prevent leaking secrets |
| Pinned base image | Reproducibility |
| Health check | Container orchestration |
| Minimal layers | Build cache efficiency |

### Python Dockerfile Template

```dockerfile
# Build stage
FROM python:3.12-slim AS builder

WORKDIR /app

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Install dependencies
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

# Production stage
FROM python:3.12-slim

WORKDIR /app

# Create non-root user
RUN useradd --create-home appuser
USER appuser

# Copy virtual environment
COPY --from=builder --chown=appuser /app/.venv /app/.venv

# Copy application
COPY --chown=appuser . .

# Set environment
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Node.js Dockerfile Template

```dockerfile
# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Production stage
FROM node:20-alpine

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Copy built application
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

USER nextjs

ENV NODE_ENV=production
ENV PORT=3000

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -q --spider http://localhost:3000/api/health || exit 1

EXPOSE 3000

CMD ["node", "server.js"]
```

### .dockerignore

```
# Dependencies
node_modules/
.venv/
__pycache__/

# Build artifacts
.next/
dist/
build/

# Environment
.env
.env.*
!.env.example

# Development
.git/
.github/
*.md
Makefile

# IDE
.vscode/
.idea/

# Tests
tests/
**/test_*
coverage/

# Secrets
*.pem
*.key
credentials.json
```

---

## Deployment Configuration

### Environment Management

| Environment | Purpose | Database |
|-------------|---------|----------|
| Development | Local dev | Local/Docker |
| Staging | Pre-prod testing | Isolated copy |
| Production | Live system | Production DB |

### Environment Variables

**Required documentation:**
```markdown
| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| DATABASE_URL | PostgreSQL connection string | Yes | - |
| REDIS_URL | Redis connection string | Yes | - |
| JWT_SECRET | Token signing secret | Yes | - |
| CORS_ORIGINS | Allowed origins (comma-sep) | No | * |
| LOG_LEVEL | Logging verbosity | No | INFO |
| SENTRY_DSN | Error tracking | No | - |
```

**Example .env.example:**
```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname

# Authentication
JWT_SECRET=change-this-in-production
JWT_EXPIRATION=3600

# External Services
REDIS_URL=redis://localhost:6379
SENTRY_DSN=

# Application
CORS_ORIGINS=http://localhost:3000
LOG_LEVEL=INFO
DEBUG=false
```

### Health Check Endpoints

**Minimum requirements:**
```python
@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.get("/health/ready")
async def readiness_check(db: Session = Depends(get_db)):
    # Check database connectivity
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ready", "database": "connected"}
    except Exception:
        raise HTTPException(503, "Database not ready")

@app.get("/health/live")
def liveness_check():
    return {"status": "alive"}
```

---

## Observability

### Logging

**Structured logging requirements:**
```python
import structlog

logger = structlog.get_logger()

# GOOD: Structured with context
logger.info(
    "user_created",
    user_id=user.id,
    email=user.email,  # Only if not PII-sensitive
    created_at=user.created_at.isoformat()
)

# BAD: Unstructured
print(f"User created: {user}")
logger.info(f"Created user {user.id}")
```

**Log levels usage:**
| Level | Use Case |
|-------|----------|
| DEBUG | Detailed diagnostic info |
| INFO | Normal operations |
| WARNING | Unexpected but handled |
| ERROR | Errors requiring attention |
| CRITICAL | System failures |

### Error Tracking

**Sentry integration checklist:**
- [ ] Sentry SDK installed
- [ ] DSN configured via environment variable
- [ ] Environment tag set (production/staging)
- [ ] Release tracking enabled
- [ ] Source maps uploaded (frontend)
- [ ] PII filtering enabled (`send_default_pii=False`)
- [ ] Sample rates configured

```python
import sentry_sdk

sentry_sdk.init(
    dsn=os.environ.get("SENTRY_DSN"),
    environment=os.environ.get("ENVIRONMENT", "development"),
    send_default_pii=False,
    traces_sample_rate=0.1,
    profiles_sample_rate=0.1,
)
```

### Metrics (Optional but Recommended)

**Key metrics to track:**
- Request count by endpoint
- Response time percentiles (p50, p95, p99)
- Error rate by type
- Active connections
- Database query time
- External API latency

---

## Database Management

### Migration System

| Framework | Migration Tool |
|-----------|----------------|
| Django | Django migrations |
| SQLAlchemy | Alembic |
| Prisma | Prisma Migrate |
| Drizzle | Drizzle Kit |
| TypeORM | TypeORM migrations |

**Requirements:**
- [ ] Migration tool configured
- [ ] Initial migration creates all tables
- [ ] Migrations are reversible
- [ ] Migration history tracked in version control

### Connection Configuration

```python
# GOOD: Pooled connections with health checks
engine = create_async_engine(
    DATABASE_URL,
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,  # Verify connection before use
    pool_recycle=300,    # Recycle connections every 5 min
)

# BAD: No pooling, no health checks
engine = create_engine(DATABASE_URL)
```

### Backup Strategy

| Requirement | Frequency |
|-------------|-----------|
| Full backup | Daily |
| Point-in-time | Continuous (if supported) |
| Backup testing | Monthly |
| Retention | 30 days minimum |

---

## Deployment Readiness

### Pre-Deployment Checklist

- [ ] All tests passing in CI
- [ ] No critical/high severity security issues
- [ ] Environment variables documented
- [ ] Database migrations tested
- [ ] Health check endpoints working
- [ ] Error tracking configured
- [ ] Logging configured
- [ ] Secrets rotated from development values
- [ ] CORS restricted to production domains
- [ ] Debug mode disabled

### Post-Deployment Verification

- [ ] Application responding on health endpoint
- [ ] Logs showing expected startup
- [ ] Error rate normal (baseline)
- [ ] Response times normal (baseline)
- [ ] Database connections successful
- [ ] External service integrations working

---

## Effort Estimation

### Quick Fix (< 1 hour)
- Adding health check endpoint
- Configuring environment variables
- Adding .dockerignore
- Enabling structured logging
- Adding CI lint step

### Moderate (1-4 hours)
- Setting up complete CI/CD pipeline
- Creating Dockerfile with best practices
- Implementing proper error tracking
- Adding database migrations
- Configuring pre-commit hooks

### Significant (> 4 hours)
- Implementing comprehensive observability
- Setting up multi-environment deployment
- Adding security scanning to CI
- Implementing backup strategy
- Creating deployment documentation
