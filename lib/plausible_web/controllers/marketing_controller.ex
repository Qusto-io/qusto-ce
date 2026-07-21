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
    # Canonical commercial tiers (Qusto Cloud): Core €9 / Growth €39 / Professional €119.
    # Source of truth: Offer Card Store Clarity + Stripe draft + OUTBOUND_TIER_STRATEGY
    # (marketing system v5, 2026-07-19). Do not reintroduce €49 Growth.
    plans = [
      %{
        name: "Core",
        price: "€9",
        period: "month",
        features: [
          "Cookieless traffic, revenue & store journey",
          "EU data residency — no consent banner",
          "Open-source core — inspect the code",
          "Managed hosting & updates",
          "Email support"
        ],
        cta: "Start Free Trial",
        featured: false
      },
      %{
        name: "Growth",
        price: "€39",
        period: "month",
        features: [
          "Everything in Core",
          "Cart abandonment recovery value",
          "Customer LTV by acquisition channel",
          "AI & channel → revenue attribution",
          "Scheduled reports · standard support"
        ],
        cta: "Start Free Trial",
        featured: true
      },
      %{
        name: "Professional",
        price: "€119",
        period: "month",
        features: [
          "Everything in Growth",
          "Multi-touch attribution models",
          "API access for BI integrations",
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
