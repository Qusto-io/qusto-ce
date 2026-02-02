defmodule Plausible.Qusto do
  @moduledoc """
  Qusto Analytics extensions for Plausible.

  This module provides advanced analytics features including:
  - E-commerce funnels with flexible step matching
  - Multi-touch attribution models
  - AI search traffic tracking and analysis

  ## Modules

  ### PostgreSQL Schemas (Configuration)
  - `Plausible.Qusto.Funnel` - Funnel definitions
  - `Plausible.Qusto.FunnelStep` - Individual funnel steps
  - `Plausible.Qusto.FunnelPreset` - Pre-built funnel templates
  - `Plausible.Qusto.AttributionModel` - Attribution model configurations
  - `Plausible.Qusto.ConversionDefinition` - Conversion definitions for attribution
  - `Plausible.Qusto.AiReferrer` - AI search engine reference data
  - `Plausible.Qusto.AiTrafficAlert` - AI traffic change alerts

  ### ClickHouse Schemas (Analytics Data)
  - `Plausible.Qusto.ClickhouseFunnelEvent` - Funnel step completions
  - `Plausible.Qusto.ClickhouseTouchpoint` - Marketing touchpoints
  - `Plausible.Qusto.ClickhouseConversion` - Conversions with attribution

  ## Usage

      # Create a new e-commerce funnel
      Plausible.Qusto.Funnel.changeset(%Plausible.Qusto.Funnel{}, %{
        name: "Checkout Funnel",
        site_id: site.id,
        funnel_type: "ecommerce",
        steps: [
          %{step_order: 1, name: "Product View", event_name: "Product View", match_type: "event"},
          %{step_order: 2, name: "Add to Cart", event_name: "Add to Cart", match_type: "event"},
          %{step_order: 3, name: "Begin Checkout", event_name: "Begin Checkout", match_type: "event"},
          %{step_order: 4, name: "Purchase", event_name: "Purchase", match_type: "event"}
        ]
      })

      # Match an AI referrer
      referrers = Plausible.Repo.all(Plausible.Qusto.AiReferrer.tracked_query())
      Plausible.Qusto.AiReferrer.match_referrer("https://chat.openai.com/...", referrers)
      # => "ChatGPT"

  """

  alias Plausible.Qusto.{
    Funnel,
    FunnelStep,
    FunnelPreset,
    AttributionModel,
    ConversionDefinition,
    AiReferrer,
    AiTrafficAlert
  }

  @doc """
  Returns the list of all Qusto PostgreSQL schema modules.
  """
  def postgres_schemas do
    [
      Funnel,
      FunnelStep,
      FunnelPreset,
      AttributionModel,
      ConversionDefinition,
      AiReferrer,
      AiTrafficAlert
    ]
  end

  @doc """
  Returns the list of all Qusto ClickHouse schema modules.
  """
  def clickhouse_schemas do
    [
      Plausible.Qusto.ClickhouseFunnelEvent,
      Plausible.Qusto.ClickhouseTouchpoint,
      Plausible.Qusto.ClickhouseConversion
    ]
  end
end
