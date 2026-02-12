# Contributing to Qusto Analytics CE

Thank you for your interest in contributing to Qusto Analytics Community Edition!

## Repository Structure

Qusto uses a dual-repository architecture:

- **qusto-analytics** (this repo): Public AGPL core analytics engine
- **qusto-ecommerce** (private): Proprietary e-commerce features

This separation ensures clear licensing and allows the community to benefit from the core platform while supporting sustainable development through premium features.

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/Qusto-io/qusto-analytics/issues) first
2. Use the bug report template
3. Include:
   - Description of the issue
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, browser, version)
   - Logs if available

### Suggesting Features

1. Check [existing discussions](https://github.com/Qusto-io/qusto-analytics/discussions)
2. Open a new discussion in "Ideas" category
3. Describe:
   - The problem you're trying to solve
   - Your proposed solution
   - Why this benefits the community

**Note**: Features related to e-commerce, advanced attribution, or AI tracking are proprietary and won't be added to CE.

### Code Contributions

#### Setup Development Environment

```bash
# Clone the repository
git clone https://github.com/Qusto-io/qusto-analytics.git
cd qusto-analytics
git checkout public-main

# Install dependencies
mix deps.get
npm install --prefix assets

# Setup database
mix ecto.setup

# Start server
mix phx.server
```

#### Development Workflow

1. **Fork the repository**
2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name public-main
   ```
3. **Make your changes**:
   - Follow the existing code style
   - Add tests for new functionality
   - Update documentation as needed
4. **Test your changes**:
   ```bash
   mix test
   mix format --check-formatted
   mix credo --strict
   ```
5. **Commit with conventional commits**:
   ```bash
   git commit -m "feat: add new analytics feature"
   ```
6. **Push and create PR**:
   ```bash
   git push origin feature/your-feature-name
   ```
   - Target the `public-main` branch
   - Fill out the PR template
   - Link related issues

## Commit Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

## Code Style

- **Elixir**: Follow [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
  - Run `mix format` before committing
  - Run `mix credo` for linting
- **JavaScript**: Follow [Standard JS](https://standardjs.com/)
  - Run `npm run lint` in assets directory
- **Line length**: 120 characters max
- **Comments**: Write clear, helpful comments for complex logic

## Testing

- Write tests for all new features
- Ensure existing tests pass
- Aim for >80% code coverage
- Test edge cases and error handling

```bash
# Run all tests
mix test

# Run specific test
mix test test/plausible/stats_test.exs

# Run with coverage
mix test --cover
```

## Pull Request Process

1. **PR checklist**:
   - [ ] Tests pass locally
   - [ ] Code is formatted (`mix format`)
   - [ ] No linter warnings (`mix credo`)
   - [ ] Documentation updated
   - [ ] CHANGELOG.md updated (if applicable)

2. **Review process**:
   - Maintainers will review within 1-2 weeks
   - Address feedback promptly
   - Be open to suggestions
   - Changes may be requested for code quality, performance, or architectural fit

3. **Merge**:
   - Approved PRs are merged by maintainers
   - Squash commits for clean history
   - Credit given in release notes

## Branching Strategy

- `public-main`: Default branch for CE development
- `feature/*`: Feature branches (from public-main)
- `fix/*`: Bug fix branches
- `docs/*`: Documentation updates

**Never submit PRs to**:
- `master` - Legacy branch being phased out
- `deploy-production` - Private deployment branch
- `private-ecommerce` - Proprietary code branch

## Community Guidelines

- Be respectful and constructive
- Help others when you can
- Follow our [Code of Conduct](CODE_OF_CONDUCT.md)
- Ask questions in [Discussions](https://github.com/Qusto-io/qusto-analytics/discussions)

## License

By contributing, you agree that your contributions will be licensed under the AGPL-3.0 license.

## Questions?

- **Development**: Ask in GitHub Discussions
- **Security**: Email security@qusto.io
- **Other**: contact@qusto.io

Thank you for helping make Qusto Analytics better! 🎉
