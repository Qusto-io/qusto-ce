# Contributing to Qusto Analytics

We welcome everyone to contribute to Qusto Analytics! This document helps you understand our architecture, set up your environment, find tasks, and open pull requests.

---

## 📋 Table of Contents

- [Understanding Qusto's Architecture](#understanding-qustos-architecture)
- [Development Setup](#development-setup)
- [Finding a Task](#finding-a-task)
- [Contributor License Agreement (CLA)](#contributor-license-agreement-cla)
- [Code Guidelines](#code-guidelines)
- [Pull Request Process](#pull-request-process)

---

## Understanding Qusto's Architecture

Qusto uses an **open-core model**. Understanding this is important before contributing.

### This Repository (qusto-ce) - Open Source (AGPLv3)

- ✅ Core analytics engine
- ✅ Dashboard UI
- ✅ Basic event tracking
- ✅ Self-hosting support
- ✅ API endpoints (public)

### Private Repositories - Proprietary

These repositories are **not open source** and are developed separately:

| Repository | Purpose |
|------------|---------|
| `qusto-funnels` | E-commerce funnel analytics |
| `qusto-ai-tracking` | AI search bot detection |
| `qusto-attribution` | Advanced attribution models |
| `qusto-api-gateway` | Service orchestration |
| `qusto-infrastructure` | DevOps configurations |

### What This Means for Contributors

1. **Your contributions remain AGPLv3** - All code in this repo is open source
2. **Integration with premium services** - We may integrate your contributions with proprietary services via APIs
3. **You retain copyright** - Your contributions remain yours, licensed under AGPLv3
4. **CLA for certain contributions** - Required when contributions might be used in premium feature integration (see below)

---

## Development Setup

The easiest way to get up and running is to use Docker for running both Postgres and ClickHouse.

### Prerequisites

Make sure the following are installed on your development machine:
- Docker ([install guide](https://docs.docker.com/get-docker/))
- Elixir/Erlang (see [`.tool-versions`](.tool-versions) for versions)
- Node.js (see [`.tool-versions`](.tool-versions) for version)

We recommend using [asdf](https://github.com/asdf-vm/asdf) for managing Elixir, Erlang, and Node.js versions.

### Start the Environment

1. Run both `make postgres` and `make clickhouse` to start database containers.

2. You can set up everything with `make install`, or run each command separately:
   ```bash
   # Download Elixir dependencies
   mix deps.get

   # Create databases in Postgres and ClickHouse
   mix ecto.create

   # Build database schema
   mix ecto.migrate

   # Seed the database (optional, see Seeds section)
   mix run priv/repo/seeds.exs

   # Install client-side dependencies
   npm ci --prefix assets
   npm ci --prefix tracker

   # Install Tailwind and Esbuild
   mix assets.setup

   # Generate tracker files
   npm run deploy --prefix tracker

   # Fetch geolocation database
   mix download_country_database
   ```

3. Run `make server` or `mix phx.server` to start the Phoenix server.

4. The system is now available on `localhost:8000`.

### Seeds

You can optionally seed your database to automatically create an account and a site with stats:

1. Run `mix run priv/repo/seeds.exs` to seed the database.
2. Start the server with `make server` and navigate to `http://localhost:8000/login`.
3. Log in with: `user@plausible.test` / `plausible`
4. You should now have a `dummy.site` site with generated stats.

Alternatively, create a new account manually:

1. Navigate to `http://localhost:8000/register` and fill in the form.
2. Use `dummy.site` as the domain.
3. Skip the JS snippet and click start collecting data.
4. Run `mix send_pageview` to generate a fake pageview event.

### Stopping Docker Containers

```bash
# Stop and remove Postgres container
make postgres-stop

# Stop and remove ClickHouse container
make clickhouse-stop
```

Volumes are preserved, so your data persists between sessions.

### Pre-commit Hooks

`pre-commit` requires Python and covers Elixir, JavaScript, and CSS:

```bash
pip install --user pre-commit
pre-commit install
```

To remove: `pre-commit uninstall`

---

## Finding a Task

### Bug Fixes

Bugs can be found in our [issue tracker](https://github.com/qusto-io/qusto-ce/issues). Issues labeled `good first issue` are great for newcomers.

### New Features

New features need to be discussed first. Please:

1. Check the [Discussions tab](https://github.com/qusto-io/qusto-ce/discussions) for existing proposals
2. Open a new discussion to propose your feature
3. Wait for feedback before starting implementation

**Important:** Some features may be better suited for premium repositories. We'll help guide you during the discussion.

### What Belongs in This Repository

| Belongs Here ✅ | Belongs in Premium Repos ❌ |
|-----------------|---------------------------|
| Core tracking improvements | E-commerce funnel logic |
| Dashboard UI enhancements | AI bot detection algorithms |
| API performance optimizations | Attribution model changes |
| Self-hosting improvements | Cloud-specific features |
| Documentation updates | Infrastructure automation |
| Bug fixes | Premium-only integrations |

---

## Contributor License Agreement (CLA)

For certain contributions, we require a Contributor License Agreement (CLA).

### When CLA is Required

- New API endpoints that premium features might integrate with
- Database schema changes
- Core event processing logic
- Authentication/authorization changes

### When CLA is NOT Required

- Documentation improvements
- Bug fixes in existing code
- UI/UX improvements (styling, layout, accessibility)
- Self-hosting guides and examples
- Test improvements
- Typo fixes

### Why We Need a CLA

The CLA allows us to:
1. Integrate open-source contributions with proprietary premium features
2. Ensure legal clarity for both parties
3. Protect your rights as a contributor
4. Maintain our ability to offer premium services

**Your contributions remain AGPLv3 licensed** - the CLA does not change this. It simply grants us permission to use your contribution in our premium services as well.

### How to Sign

When you open a pull request that requires a CLA:
1. Our bot will comment with a link to the CLA
2. Read and sign the CLA electronically
3. Your PR will be updated automatically

[View the full CLA text](CLA.md) *(Coming soon)*

---

## Code Guidelines

### AGPLv3 Compliance

- All code in this repo is AGPLv3 licensed
- Maintain upstream Plausible attribution in file headers where present
- Document your modifications clearly in commit messages

### Coding Standards

**Elixir:**
- Follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- Use `mix format` before committing
- Run `mix credo` for static analysis

**JavaScript:**
- Use ESLint configuration provided
- Run `npm run lint --prefix assets` before committing

**CSS:**
- Use TailwindCSS utility classes
- Avoid custom CSS unless necessary

### API Design

If your contribution adds or modifies APIs that premium features might use:

1. **Document thoroughly** - Include clear descriptions and examples
2. **Add OpenAPI specs** - Update API documentation
3. **Consider backward compatibility** - Avoid breaking changes
4. **CLA required** - See section above

### Testing

- **Unit tests** for business logic (`test/` directory)
- **Integration tests** for API endpoints
- **Ensure self-hosted deployments work** - Test with `docker-compose`
- Run the full test suite: `mix test`

### Commit Messages

Follow conventional commits format:

```
type(scope): short description

Longer description if needed.

Fixes #123
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

---

## Pull Request Process

1. **Fork and branch** - Create a feature branch from `main`
2. **Make changes** - Follow the code guidelines above
3. **Test locally** - Run tests and verify self-hosted deployment works
4. **Open PR** - Use our [PR template](.github/PULL_REQUEST_TEMPLATE.md)
5. **Sign CLA if needed** - Our bot will guide you
6. **Address feedback** - Respond to review comments
7. **Merge** - Once approved, we'll merge your PR

### PR Checklist

Before opening a PR, ensure:

- [ ] Tests pass locally (`mix test`)
- [ ] Code is formatted (`mix format`)
- [ ] No linting errors
- [ ] Self-hosted deployment tested
- [ ] Documentation updated if needed
- [ ] Commit messages follow conventions

---

## Questions?

- **General questions**: [Discussions](https://github.com/qusto-io/qusto-ce/discussions)
- **Self-hosted support**: [Self-hosted forum](https://github.com/qusto-io/qusto-ce/discussions/categories/self-hosted-support)
- **Security issues**: Email security@qusto.io (do not open public issues)

Thank you for contributing to Qusto Analytics! 🙏
