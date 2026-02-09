defmodule Plausible.Qusto.ClickhouseFunnelEvent do
  @moduledoc """
  ClickHouse schema for funnel step completion events.

  This table tracks individual funnel step completions, optimized for
  ClickHouse's windowFunnel() function for funnel analysis.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "qusto_funnel_events" do
    field :site_id, Ch, type: "UInt64"
    field :funnel_id, Ch, type: "UInt64"
    field :user_id, Ch, type: "UInt64"
    field :session_id, Ch, type: "UInt64"

    field :step_name, Ch, type: "LowCardinality(String)"
    field :step_order, Ch, type: "UInt8"
    field :timestamp, :naive_datetime

    # E-commerce context
    field :product_id, Ch, type: "LowCardinality(String)"
    field :product_name, :string
    field :product_category, Ch, type: "LowCardinality(String)"
    field :revenue, Ch, type: "Nullable(Decimal64(3))"

    # Attribution context
    field :referrer_source, Ch, type: "LowCardinality(String)"
    field :utm_campaign, :string
    field :ai_referral_source, Ch, type: "LowCardinality(String)"
  end

  def new(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :site_id,
      :funnel_id,
      :user_id,
      :session_id,
      :step_name,
      :step_order,
      :timestamp,
      :product_id,
      :product_name,
      :product_category,
      :revenue,
      :referrer_source,
      :utm_campaign,
      :ai_referral_source
    ])
    |> validate_required([:site_id, :funnel_id, :user_id, :step_name, :step_order, :timestamp])
  end
end
