# Contributing to Qusto Analytics

We welcome everyone to contribute to Qusto Analytics! This document helps you understand our architecture, set up your environment, find tasks, and open pull requests.

---

## 📋 Table of Contents

- [Understanding Qusto's Architecture](#understanding-qustos-architecture)
- [Development Setup](#development-setup)
- [Finding a Task](#finding-a-task)
- [Licence of contributions](#licence-of-contributions)
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
2. **You retain copyright** - Your contributions remain yours, licensed under AGPLv3
3. **Inbound = outbound** - Contributions are accepted under the GNU AGPL v3.0. They are not used in closed software. See [Licence of contributions](#licence-of-contributions)

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

## Licence of contributions

Contributions are accepted under the GNU AGPL v3.0, the licence of this repository (inbound = outbound). Each commit must carry a `Signed-off-by:` line certifying the Developer Certificate of Origin 1.1 (https://developercertificate.org/). We do not ask for a CLA, and we do not use contributions to this repository in closed software.

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

If your contribution adds or modifies a public API:

1. **Document thoroughly** - Include clear descriptions and examples
2. **Add OpenAPI specs** - Update API documentation
3. **Consider backward compatibility** - Avoid breaking changes

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

Signed-off-by: Your Name <you@example.com>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

The `Signed-off-by` line is the Developer Certificate of Origin. Use your own name and email.

---

## Pull Request Process

1. **Fork and branch** - Create a feature branch from `main`
2. **Make changes** - Follow the code guidelines above
3. **Test locally** - Run tests and verify self-hosted deployment works
4. **Open PR** - Use our [PR template](.github/PULL_REQUEST_TEMPLATE.md)
5. **Signed-off-by** - Every commit in the pull request carries the DCO trailer. CI checks this
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
