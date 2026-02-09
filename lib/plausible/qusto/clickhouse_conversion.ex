defmodule Plausible.Qusto.ClickhouseConversion do
  @moduledoc """
  ClickHouse schema for conversions with full attribution breakdown.

  Stores conversion events with both first-touch and last-touch
  attribution data, enabling flexible attribution analysis.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "qusto_conversions" do
    field :site_id, Ch, type: "UInt64"
    field :user_id, Ch, type: "UInt64"
    field :session_id, Ch, type: "UInt64"
    field :conversion_id, Ecto.UUID
    field :timestamp, :naive_datetime

    # Conversion details
    field :conversion_name, Ch, type: "LowCardinality(String)"
    field :revenue, Ch, type: "Nullable(Decimal64(3))"
    field :currency, Ch, type: "FixedString(3)"

    # E-commerce details
    field :order_id, :string
    field :product_ids, {:array, :string}

    # First touch attribution
    field :first_touch_source, Ch, type: "LowCardinality(String)"
    field :first_touch_medium, Ch, type: "LowCardinality(String)"
    field :first_touch_campaign, :string
    field :first_touch_ai_source, Ch, type: "LowCardinality(String)"

    # Last touch attribution
    field :last_touch_source, Ch, type: "LowCardinality(String)"
    field :last_touch_medium, Ch, type: "LowCardinality(String)"
    field :last_touch_campaign, :string
    field :last_touch_ai_source, Ch, type: "LowCardinality(String)"

    # Journey metadata
    field :touchpoint_count, Ch, type: "UInt8"
    field :days_to_conversion, Ch, type: "UInt16"

    # Consent level
    field :consent_level, Ch, type: "LowCardinality(String)"
  end

  def new(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :site_id,
      :user_id,
      :session_id,
      :conversion_id,
      :timestamp,
      :conversion_name,
      :revenue,
      :currency,
      :order_id,
      :product_ids,
      :first_touch_source,
      :first_touch_medium,
      :first_touch_campaign,
      :first_touch_ai_source,
      :last_touch_source,
      :last_touch_medium,
      :last_touch_campaign,
      :last_touch_ai_source,
      :touchpoint_count,
      :days_to_conversion,
      :consent_level
    ])
    |> validate_required([:site_id, :user_id, :conversion_id, :timestamp, :conversion_name])
  end

  @doc """
  Creates a conversion record with attribution from touchpoints.
  """
  def from_touchpoints(conversion_attrs, first_touchpoint, last_touchpoint) do
    attrs =
      conversion_attrs
      |> Map.merge(%{
        first_touch_source: first_touchpoint.referrer_source,
        first_touch_medium: first_touchpoint.referrer_medium,
        first_touch_campaign: first_touchpoint.utm_campaign,
        first_touch_ai_source: first_touchpoint.ai_referral_source,
        last_touch_source: last_touchpoint.referrer_source,
        last_touch_medium: last_touchpoint.referrer_medium,
        last_touch_campaign: last_touchpoint.utm_campaign,
        last_touch_ai_source: last_touchpoint.ai_referral_source
      })

    new(attrs)
  end
end
