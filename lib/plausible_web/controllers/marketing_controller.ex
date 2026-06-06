defmodule PlausibleWeb.MarketingController do
  use PlausibleWeb, :controller

  plug PlausibleWeb.RequireLoggedOutPlug

  # Product Pages
  def product_overview(conn, _params) do
    render(conn, "product_overview.html",
      page_title: "Product - Qusto Analytics",
      layout: {PlausibleWeb.LayoutView, "app.html"}
    )
  end

  def ecommerce(conn, _params) do
    features = [
      %{
        icon: "🛒",
        title: "Product-Level Analytics",
        description:
          "See which products drive revenue, not just pageviews. Track SKU performance, product category analytics, and revenue attribution."
      },
      %{
        icon: "📊",
        title: "Cart Abandonment Tracking",
        description:
          "Identify drop-off points and calculate lost revenue automatically. Get insights into why customers leave before purchasing."
      },
      %{
        icon: "🎯",
        title: "Conversion Funnels",
        description:
          "Track the complete journey: product view → add to cart → checkout → purchase. Optimize each step."
      },
      %{
        icon: "💰",
        title: "Revenue Analytics",
        description:
          "Track revenue by source, campaign, product, and customer segment. Understand what drives your bottom line."
      }
    ]

    render(conn, "ecommerce.html",
      page_title: "E-commerce Analytics - Qusto",
      features: features,
      layout: {PlausibleWeb.LayoutView, "app.html"}
    )
  end

  def ai_search(conn, _params) do
    render(conn, "ai_search.html",
      page_title: "Traffic Sources & AI Referrals - Qusto",
      layout: {PlausibleWeb.LayoutView, "app.html"}
    )
  end

  def funnels(conn, _params) do
    render(conn, "funnels.html",
      page_title: "Conversion Funnels - Qusto",
      layout: {PlausibleWeb.LayoutView, "app.html"}
    )
  end

  def privacy(conn, _params) do
    render(conn, "privacy_product.html",
      page_title: "Privacy & GDPR - Qusto",
      layout: {PlausibleWeb.LayoutView, "app.html"}
    )
  end

  # Pricing
  def pricing(conn, _params) do
    # TODO(QUS-REBRAND): confirm live prices — placeholders until billing sign-off
    plans = [
      %{
        name: "Community Edition",
        price: "Free",
        period: "self-hosted",
        features: [
          "Open-source core analytics",
          "Privacy-first event tracking",
          "Basic e-commerce events",
          "Self-hosting — inspect the code",
          "Community support"
        ],
        cta: "View on GitHub",
        featured: false
      },
      %{
        name: "Growth",
        price: "{{PRICE_GROWTH}}",
        period: "month",
        features: [
          "Managed hosting in the EU",
          "E-commerce funnels & revenue",
          "Traffic sources including AI",
          "Automatic updates & backups",
          "Standard support"
        ],
        cta: "Start Free Trial",
        featured: true
      },
      %{
        name: "Professional",
        price: "{{PRICE_PRO}}",
        period: "month",
        features: [
          "Everything in Growth",
          "Deeper behavioural analysis",
          "Multi-touch attribution",
          "More team seats",
          "Priority support"
        ],
        cta: "Contact Sales",
        featured: false
      }
    ]

    render(conn, "pricing.html",
      page_title: "Pricing - Qusto Analytics",
      plans: plans,
      layout: {PlausibleWeb.LayoutView, "app.html"}
    )
  end

  # Company Pages
  def about(conn, _params) do
    render(conn, "about.html",
      page_title: "About - Qusto Analytics",
      layout: {PlausibleWeb.LayoutView, "app.html"}
    )
  end

  def contact(conn, _params) do
    render(conn, "contact.html",
      page_title: "Contact Us - Qusto",
      layout: {PlausibleWeb.LayoutView, "app.html"}
    )
  end

  # Legal Pages
  def privacy_policy(conn, _params) do
    render(conn, "privacy_policy.html",
      page_title: "Privacy Policy - Qusto Analytics",
      layout: {PlausibleWeb.LayoutView, "app.html"}
    )
  end

  def terms(conn, _params) do
    render(conn, "terms.html",
      page_title: "Terms of Service - Qusto Analytics",
      layout: {PlausibleWeb.LayoutView, "app.html"}
    )
  end

  def gdpr(conn, _params) do
    render(conn, "gdpr.html",
      page_title: "GDPR Compliance - Qusto Analytics",
      layout: {PlausibleWeb.LayoutView, "app.html"}
    )
  end
end
