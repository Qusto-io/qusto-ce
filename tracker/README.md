# Qusto Tracker

This contains Qusto tracker script and NPM package which Qusto users integrate into
their site and which captures pageviews and more.

> **Note:** The tracker is based on the Qusto Analytics open-source project. Qusto is a derivative work and attribution to Qusto is maintained throughout the codebase.

## Development

See also [ARCHITECTURE.md](./ARCHITECTURE.md)

### Dependencies

To download dependencies, do:

```bash
npm install
npx playwright install # installs browsers used by playwright
```

### Compilation

Compile tracker code by `node compile.js`.

Use `node compile.js --watch` to watch for changes.

Use `node compile.js --web-snippet` if you need to update web snippet code.

### Tests

Tests can be run in UI mode via `npm run playwright --ui`. This helps with debugging.

### NPM package

To test changes to the npm package by installing the local version against a test project, we recommend:

- installing [yalc](https://github.com/wclr/yalc) via `npm install yalc -g`
- compiling the tracker
- running `yalc publish` in `tracker/npm_package` directory

More instructions can be found in [yalc repo](https://github.com/wclr/yalc).

## Cloud deployment

Handled via PRs. When making tracker changes, it's required to:

- Tag your PR with a `tracker release:` label
- Update `tracker/CHANGELOG.md`

After merge github actions automatically:

- includes the updated tracker scripts in the next cloud deploy
- updates npm package package.json and CHANGELOG.md with the new version
- releases the new package version on NPM.
