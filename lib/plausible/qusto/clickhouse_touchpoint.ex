defmodule Plausible.Qusto.ClickhouseTouchpoint do
  @moduledoc """
  ClickHouse schema for marketing touchpoints in the user journey.

  Tracks all marketing interactions that contribute to the attribution
  analysis, including AI search referrals.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "qusto_touchpoints" do
    field :site_id, Ch, type: "UInt64"
    field :user_id, Ch, type: "UInt64"
    field :session_id, Ch, type: "UInt64"
    field :timestamp, :naive_datetime

    # Source info
    field :referrer_source, Ch, type: "LowCardinality(String)"
    field :referrer_medium, Ch, type: "LowCardinality(String)"
    field :utm_source, :string
    field :utm_medium, :string
    field :utm_campaign, :string
    field :utm_content, :string
    field :utm_term, :string

    # AI search tracking
    field :ai_referral_source, Ch, type: "LowCardinality(String)"

    # Click IDs
    field :click_id_param, Ch, type: "LowCardinality(String)"
    field :click_id_value, :string

    # Touchpoint sequence
    field :touchpoint_order, Ch, type: "UInt8"
    field :days_since_first_touch, Ch, type: "UInt16"

    # Landing page
    field :landing_page, :string

    # Device/geo context
    field :device_type, Ch, type: "LowCardinality(String)"
    field :country_code, Ch, type: "FixedString(2)"
  end

  def new(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :site_id,
      :user_id,
      :session_id,
      :timestamp,
      :referrer_source,
      :referrer_medium,
      :utm_source,
      :utm_medium,
      :utm_campaign,
      :utm_content,
      :utm_term,
      :ai_referral_source,
      :click_id_param,
      :click_id_value,
      :touchpoint_order,
      :days_since_first_touch,
      :landing_page,
      :device_type,
      :country_code
    ])
    |> validate_required([:site_id, :user_id, :timestamp, :touchpoint_order])
  end
end
