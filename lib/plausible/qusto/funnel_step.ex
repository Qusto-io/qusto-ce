defmodule Plausible.Qusto.FunnelStep do
  @moduledoc """
  Schema for individual steps within a Qusto funnel.

  Steps can match events by:
  - Event name (e.g., 'Product View', 'Add to Cart', 'Purchase')
  - URL pattern (e.g., '/product/*', '/cart', '/checkout/*')
  - Both event name and URL pattern

  Additional filters can be applied via the JSONB filters field.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @match_types ["event", "pageview", "both"]

  schema "qusto_funnel_steps" do
    field :step_order, :integer
    field :name, :string
    field :event_name, :string
    field :url_pattern, :string
    field :match_type, :string, default: "event"
    field :filters, :map, default: %{}

    belongs_to :funnel, Plausible.Qusto.Funnel

    timestamps(updated_at: false)
  end

  def match_types, do: @match_types

  def changeset(step \\ %__MODULE__{}, attrs) do
    step
    |> cast(attrs, [:step_order, :name, :event_name, :url_pattern, :match_type, :filters])
    |> validate_required([:step_order, :name, :match_type])
    |> validate_inclusion(:match_type, @match_types)
    |> validate_number(:step_order, greater_than: 0, less_than_or_equal_to: 10)
    |> validate_match_criteria()
  end

  defp validate_match_criteria(changeset) do
    match_type = get_field(changeset, :match_type)
    event_name = get_field(changeset, :event_name)
    url_pattern = get_field(changeset, :url_pattern)

    case {match_type, event_name, url_pattern} do
      {"event", nil, _} ->
        add_error(changeset, :event_name, "is required for event match type")

      {"pageview", _, nil} ->
        add_error(changeset, :url_pattern, "is required for pageview match type")

      {"both", nil, _} ->
        add_error(changeset, :event_name, "is required for both match type")

      {"both", _, nil} ->
        add_error(changeset, :url_pattern, "is required for both match type")

      _ ->
        changeset
    end
  end
end
