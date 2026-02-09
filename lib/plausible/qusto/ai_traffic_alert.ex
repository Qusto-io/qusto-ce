defmodule Plausible.Qusto.AiTrafficAlert do
  @moduledoc """
  Schema for configuring alerts on AI traffic changes.

  Alert types:
  - threshold: Triggers when AI traffic exceeds a percentage threshold
  - spike: Triggers on sudden increase in AI traffic
  - drop: Triggers on sudden decrease in AI traffic
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @alert_types ["threshold", "spike", "drop"]

  schema "qusto_ai_traffic_alerts" do
    field :alert_type, :string
    field :ai_source, :string
    field :threshold_percent, :decimal
    field :comparison_period_days, :integer, default: 7
    field :notification_email, :string
    field :notification_webhook, :string
    field :is_active, :boolean, default: true

    belongs_to :site, Plausible.Site

    timestamps(updated_at: false)
  end

  def alert_types, do: @alert_types

  def changeset(alert \\ %__MODULE__{}, attrs) do
    alert
    |> cast(attrs, [
      :alert_type,
      :ai_source,
      :threshold_percent,
      :comparison_period_days,
      :notification_email,
      :notification_webhook,
      :is_active,
      :site_id
    ])
    |> validate_required([:alert_type, :site_id])
    |> validate_inclusion(:alert_type, @alert_types)
    |> validate_number(:threshold_percent, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_number(:comparison_period_days, greater_than: 0, less_than_or_equal_to: 90)
    |> validate_notification_method()
    |> validate_email_format()
    |> validate_webhook_format()
  end

  defp validate_notification_method(changeset) do
    email = get_field(changeset, :notification_email)
    webhook = get_field(changeset, :notification_webhook)

    if is_nil(email) and is_nil(webhook) do
      add_error(changeset, :notification_email, "at least one notification method is required")
    else
      changeset
    end
  end

  defp validate_email_format(changeset) do
    case get_change(changeset, :notification_email) do
      nil ->
        changeset

      email when is_binary(email) ->
        if String.match?(email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/) do
          changeset
        else
          add_error(changeset, :notification_email, "must be a valid email address")
        end

      _ ->
        changeset
    end
  end

  defp validate_webhook_format(changeset) do
    case get_change(changeset, :notification_webhook) do
      nil ->
        changeset

      webhook when is_binary(webhook) ->
        if String.starts_with?(webhook, "https://") do
          changeset
        else
          add_error(changeset, :notification_webhook, "must be a valid HTTPS URL")
        end

      _ ->
        changeset
    end
  end
end
