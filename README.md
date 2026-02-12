# Qusto Analytics - Community Edition

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

**Privacy-first, open-source web analytics**

Qusto Analytics Community Edition is a lightweight, privacy-focused web analytics platform. Built on Elixir and ClickHouse, providing real-time insights without compromising visitor privacy.

> 🔓 **This is the open-source core**. Premium features (e-commerce funnels, AI search tracking, advanced attribution) are available in [Qusto Cloud](https://qusto.io).

## Features (Community Edition)

- **Privacy-First**: No cookies, fully GDPR/CCPA compliant
- **Lightweight**: <1KB script size
- **Real-Time**: Live visitor data and instant insights
- **Event Tracking**: Custom events and goal tracking
- **Basic Funnels**: Simple conversion funnel tracking
- **Data Export**: CSV and API export capabilities
- **Self-Hosted**: Full control of your data

## Not Included in CE

This Community Edition does **NOT** include proprietary features:
- ❌ Advanced e-commerce analytics
- ❌ Multi-touch attribution
- ❌ AI-powered insights and ChatGPT traffic detection
- ❌ SSO/SAML authentication
- ❌ Priority support

For enterprise features, see: [Qusto Cloud Pricing](https://qusto.io/pricing)

## Quick Start

### Docker Compose (Recommended)

```bash
git clone https://github.com/Qusto-io/qusto-analytics.git
cd qusto-analytics
git checkout public-main
cp config/config.example.env config/.env
# Edit config/.env with your settings
docker-compose up -d
```

Visit http://localhost:8000 to access your analytics dashboard.

### Manual Installation

See [Installation Guide](https://docs.qusto.io/self-hosting) for detailed instructions.

## Documentation

- **Self-Hosting Guide**: https://docs.qusto.io/self-hosting
- **API Documentation**: https://docs.qusto.io/api
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)
- **Architecture**: See [ARCHITECTURE.md](ARCHITECTURE.md)

## Comparison: CE vs Cloud

| Feature | Community Edition | Qusto Cloud |
|---------|------------------|-------------|
| Core Analytics | ✅ | ✅ |
| Dashboard | ✅ | ✅ |
| API Access | ✅ | ✅ |
| Goal Tracking | ✅ | ✅ |
| Data Export | ✅ | ✅ |
| Basic Funnels | ✅ | ✅ |
| E-commerce Analytics | ❌ | ✅ |
| AI Search Tracking | ❌ | ✅ |
| Advanced Attribution | ❌ | ✅ |
| SSO/SAML | ❌ | ✅ |
| Support | Community | Priority |
| Hosting | Your servers | EU-hosted |
| Maintenance | You manage | We manage |

## License

**GNU Affero General Public License v3.0 (AGPL-3.0)**

This ensures:
- ✓ Free to use, modify, distribute
- ✓ Open source forever
- ✓ Network use requires source disclosure
- ✗ Cannot relicense as proprietary

See [LICENSE](LICENSE) for full terms.

## Built on Plausible

Qusto Analytics is a fork of [Plausible Analytics](https://github.com/plausible/analytics).
We maintain compatibility with upstream and contribute improvements back.

**Key differences from Plausible**:
- Enhanced for European e-commerce businesses
- Focus on GDPR compliance and privacy
- Improved dark mode and UI
- Additional localization support

## Support

- **Community**: [GitHub Discussions](https://github.com/Qusto-io/qusto-analytics/discussions)
- **Documentation**: https://docs.qusto.io
- **Issues**: [GitHub Issues](https://github.com/Qusto-io/qusto-analytics/issues)
- **Enterprise**: https://qusto.io/contact

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Sponsors

Qusto Analytics is developed by [Qusto.io](https://qusto.io) with support from our cloud customers.

---

Made with ❤️ by the Qusto team | [Website](https://qusto.io) | [Docs](https://docs.qusto.io) | [Twitter](https://twitter.com/qusto_io)
