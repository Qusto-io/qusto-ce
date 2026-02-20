# Qusto Analytics - Core Engine

> **🔓 Open Source Core** | **💎 Premium Features Available**
> This is the open-source core analytics engine. Premium features (e-commerce funnels, AI search tracking, advanced attribution) are available in [Qusto Cloud](https://qusto.io).

<p align="center">
  <a href="https://qusto.io/">
    <img src="https://raw.githubusercontent.com/qusto-io/qusto-ce/main/assets/static/images/qusto-logo.png" width="140px" alt="Qusto Analytics" />
  </a>
</p>
<p align="center">
    <a href="https://qusto.io/simple-web-analytics">Simple Metrics</a> |
    <a href="https://qusto.io/lightweight-web-analytics">Lightweight Script</a> |
    <a href="https://qusto.io/privacy-focused-web-analytics">Privacy Focused</a> |
    <a href="https://qusto.io/open-source-website-analytics">Open Source</a> |
    <a href="https://docs.qusto.io">Docs</a> |
    <a href="https://github.com/qusto-io/qusto-ce/blob/main/CONTRIBUTING.md">Contributing</a>
    <br /><br />
</p>

[Qusto Analytics](https://qusto.io/) is a privacy-friendly, GDPR-compliant web analytics platform designed for European SMB e-commerce businesses. It doesn't use cookies and is fully compliant with GDPR, CCPA and PECR. You can self-host Qusto Analytics or use our managed Qusto Cloud service. Made and hosted in the EU 🇪🇺

---

## 📋 Table of Contents

- [Open-Core Model](#-open-core-model)
- [Self-Hosting vs Qusto Cloud](#-self-hosting-vs-qusto-cloud)
- [Why Qusto?](#-why-qusto)
- [Built on Plausible](#-built-on-plausible)
- [Tech Stack](#-tech-stack-core-engine)
- [Getting Started](#-getting-started)
- [Contributors](#-contributors)
- [License](#-license--trademarks)

---

## 🔓 Open-Core Model

Qusto uses an **open-core model** that balances open-source values with sustainable business practices.

### What's Open Source (This Repository)

- ✅ Core analytics engine
- ✅ Privacy-focused event tracking
- ✅ Dashboard UI
- ✅ API access
- ✅ Self-hosting support
- ✅ Basic goal tracking
- ✅ CSV/API data export

### What's Proprietary (Qusto Cloud Only)

- 💎 **E-commerce Funnels**: Multi-step conversion tracking, abandoned cart analysis
- 💎 **AI Search Tracking**: Detect and analyze visits from ChatGPT, Perplexity, Claude, and other AI assistants
- 💎 **Advanced Attribution**: Cookieless attribution with 94% accuracy
- 💎 **Priority Support**: Dedicated support from our team

### Why This Model?

We believe in **sustainable open source**. The open-core model allows us to:

1. **Keep the core free forever** - Self-host without limits
2. **Fund ongoing development** - Premium features support the project
3. **Maintain transparency** - Core analytics logic is open for audit
4. **Give you choice** - Start free, upgrade when you need more

---

## 📊 Self-Hosting vs Qusto Cloud

| Feature | Self-Hosted (Free) | Qusto Cloud |
|---------|-------------------|-------------|
| Core Analytics | ✅ | ✅ |
| Dashboard | ✅ | ✅ |
| API Access | ✅ | ✅ |
| Goal Tracking | ✅ | ✅ |
| Data Export | ✅ | ✅ |
| E-commerce Funnels | ❌ | ✅ |
| AI Search Tracking | ❌ | ✅ |
| Advanced Attribution | ❌ | ✅ |
| Support | Community | Priority |
| Hosting | Your servers | EU-hosted (Hetzner Germany) |
| Maintenance | You manage | We manage |
| GDPR Compliance | Your responsibility | Guaranteed |

**[Start with Qusto Cloud →](https://qusto.io/pricing)** or **[Self-host →](#-getting-started)**

---

## ✨ Why Qusto?

Here's what makes Qusto Analytics a great choice for privacy-focused analytics:

- **Clutter Free**: Simple web analytics that cuts through the noise. Get all the important insights on one single page. No training necessary.
- **GDPR/CCPA/PECR compliant**: Measure traffic, not individuals. No personal data or IP addresses are ever stored. We don't use cookies or any other persistent identifiers.
- **Lightweight**: Our tracking script is tiny, making your website quicker to load. You can also send events directly to our Events API.
- **Email or Slack reports**: Keep an eye on your traffic with weekly and/or monthly email or Slack reports. You can also get traffic spike notifications.
- **Invite team members and share stats**: Your website stats are private by default but you can choose to make them public or invite team members with different roles.
- **Define key goals and track conversions**: Create custom events with custom dimensions to track conversions and understand the trends that matter.
- **EU-First**: All data processing happens exclusively in the EU on European-owned infrastructure.

---

## 🙏 Built on Plausible

Qusto Analytics is forked from [Plausible Analytics](https://github.com/plausible/analytics) (AGPLv3). We're grateful to the Plausible team for creating excellent open-source analytics software.

**Key differences from Plausible:**

- 🇪🇺 Enhanced EU/GDPR focus with EU-only hosting
- 🛒 Integration with proprietary premium features (funnels, AI tracking)
- 🎯 Optimized for European SMB e-commerce businesses
- 🤖 AI search bot detection and tracking (premium)

See [UPSTREAM.md](UPSTREAM.md) for detailed comparison and our upstream sync strategy.

---

## 🛠 Tech Stack (Core Engine)

- **Backend**: Elixir/Phoenix
- **Analytics DB**: ClickHouse
- **Metadata DB**: PostgreSQL
- **Cache**: Redis
- **Frontend**: React with TailwindCSS

*Note: Premium features use additional microservices that are not included in this repository.*

---

## 🚀 Getting Started

### Qusto Cloud (Recommended)

The easiest way to get started is with [Qusto Cloud](https://qusto.io/pricing). It takes 2 minutes to start counting your stats with high availability, backups, security and maintenance all done for you.

### Self-Hosting

Qusto Analytics can be self-hosted on your own infrastructure. We provide Docker images and detailed documentation.

**Requirements:**
- Docker and Docker Compose
- PostgreSQL 14+
- ClickHouse 23+
- At least 2GB RAM

**Quick Start:**

```bash
# Clone the repository
git clone https://github.com/qusto-io/qusto-ce.git
cd qusto-ce

# Copy environment template
cp .env.example .env

# Start with Docker Compose
docker-compose up -d
```

**Detailed Instructions:** See our [Self-Hosting Guide](https://docs.qusto.io/self-hosting).

**Community Support:** Self-hosted installations are community supported. Ask questions in our [Discussions](https://github.com/qusto-io/qusto-ce/discussions/categories/self-hosted-support).

---

## 👥 Contributors

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) before submitting a pull request.

For anyone wishing to contribute, please note that this repository uses an open-core model. Contributions to this repo remain AGPLv3 licensed.

---

## 📜 License & Trademarks

Qusto Analytics core is open source under the **GNU Affero General Public License Version 3 (AGPLv3)**. See [LICENSE](LICENSE).

The JavaScript tracker is released under the **MIT license** to avoid AGPL virality issues. See [tracker/LICENSE.md](tracker/LICENSE.md).

### Attribution

This software is based on [Plausible Analytics](https://github.com/plausible/analytics) by Plausible Insights OÜ, licensed under AGPLv3.

Copyright (c) 2024-present Qusto. Qusto Analytics name and logo are trademarks of Qusto.

Original Plausible Analytics copyright (c) 2018-present Plausible Insights OÜ.

---

<p align="center">
  <strong>Questions?</strong> Open a <a href="https://github.com/qusto-io/qusto-ce/discussions">Discussion</a> or contact <a href="mailto:support@qusto.io">support@qusto.io</a>
</p>
