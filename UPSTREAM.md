# Upstream Attribution & Differences

Qusto Analytics is forked from [Plausible Analytics](https://github.com/plausible/analytics) v2.1.0 (January 2025).

---

## 🙏 Gratitude to Plausible

We're deeply grateful to the Plausible team for creating excellent, privacy-focused analytics software and releasing it as open source under AGPLv3.

Plausible has demonstrated that privacy-respecting analytics can be both effective and sustainable. Their work has been foundational to what we're building at Qusto.

**Plausible Team:** [plausible.io/about](https://plausible.io/about)

---

## Key Differences from Plausible

### Architecture

| Aspect | Plausible | Qusto |
|--------|-----------|-------|
| Model | Monolithic application | Open-core with microservices |
| Premium features | Built into main app | Separate private repositories |
| Deployment | Single application | Core + optional premium services |

### Target Market

| Aspect | Plausible | Qusto |
|--------|-----------|-------|
| Focus | General website analytics | European SMB e-commerce |
| Geographic | Global market | EU-first, GDPR-focused |
| Primary users | Websites of all types | E-commerce, AI developers |

### Premium Features (Qusto Only)

Qusto extends the open-source core with proprietary premium features developed in separate private repositories. These include enhanced e-commerce analytics, AI search traffic detection, and advanced attribution capabilities.

### Hosting Philosophy

| Aspect | Plausible | Qusto |
|--------|-----------|-------|
| Cloud hosting | Global CDN, EU/US options | EU-only (Hetzner Germany) |
| Infrastructure | Mix of providers | European-owned only |
| Data residency | EU option available | EU mandatory |
| GDPR approach | Compliant | EU-centric by design |

---

## Upstream Sync Strategy

We periodically merge updates from upstream Plausible to benefit from:

- 🐛 Bug fixes
- ⚡ Performance improvements
- 🔒 Security patches
- ✨ New core features

### Sync Schedule

| Activity | Frequency |
|----------|-----------|
| Security patches | Immediate (within 48 hours) |
| Bug fixes | Monthly review |
| Feature updates | Quarterly review |
| Major version upgrades | As needed, with testing |

### Sync Process

1. **Monitor** - Watch Plausible releases and changelog
2. **Evaluate** - Assess relevance and compatibility
3. **Test** - Apply changes to development environment
4. **Adapt** - Modify for Qusto-specific requirements
5. **Merge** - Integrate into main branch
6. **Document** - Update CHANGELOG with upstream credits

---

## Contributing Back to Plausible

When we make improvements to the core analytics engine that would benefit all Plausible users, we contribute them back upstream under AGPLv3.

### Types of Upstream Contributions

| Contribution Type | Example |
|-------------------|---------|
| Bug fixes | Event processing edge cases |
| Performance | Query optimizations |
| UI/UX | Accessibility improvements |
| Documentation | Setup guides, API docs |
| Security | Vulnerability fixes |

### What We Don't Contribute Back

- Qusto-specific branding
- Premium feature integrations
- EU-specific hosting configurations
- Business logic for proprietary features

---

## File Attribution

Files that originate from Plausible maintain their original copyright headers:

```elixir
# Copyright (c) 2018-present Plausible Insights OÜ
# Licensed under AGPLv3
#
# Modified by Qusto - see CHANGELOG for details
```

New files created by Qusto use:

```elixir
# Copyright (c) 2024-present Qusto
# Licensed under AGPLv3
#
# Based on Plausible Analytics (https://github.com/plausible/analytics)
```

---

## License Compliance

### AGPLv3 Requirements Met

- ✅ Source code publicly available
- ✅ All Plausible copyright notices preserved
- ✅ AGPLv3 license maintained for this repository
- ✅ Modifications clearly documented
- ✅ Network use provisions respected

### Tracker Script

The JavaScript tracker remains under MIT license (as in Plausible) to avoid AGPL virality issues for users embedding the script:

- Location: [tracker/LICENSE.md](tracker/LICENSE.md)
- Reason: Ensures users can embed the tracker without AGPLv3 obligations

---

## Version Tracking

| Qusto Version | Based on Plausible | Last Sync |
|---------------|-------------------|-----------|
| v0.1.x | v2.1.0 | January 2025 |

---

## Questions?

### About our relationship with Plausible

Open a [Discussion](https://github.com/qusto-io/qusto-analytics/discussions) with the `upstream` tag.

### About the open-core model

See [README.md](README.md#-open-core-model) for details.

### For Plausible users considering Qusto

Qusto is ideal if you:
- Need EU-only data hosting
- Want e-commerce funnel analytics
- Need AI search traffic tracking
- Prefer European infrastructure

Stick with Plausible if you:
- Want a simpler, all-in-one solution
- Don't need EU-specific hosting
- Don't need e-commerce or AI tracking features

---

## Acknowledgments

- **Plausible Insights OÜ** - For creating and maintaining Plausible Analytics
- **Plausible Contributors** - For their open-source contributions
- **AGPLv3 License** - For enabling sustainable open-source business models

---

*Last updated: January 2025*
