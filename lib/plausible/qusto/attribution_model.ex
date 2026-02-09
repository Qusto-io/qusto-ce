defmodule Plausible.Qusto.AttributionModel do
  @moduledoc """
  Schema for custom attribution model configurations.

  Supports multiple attribution model types:
  - first_touch: 100% credit to first interaction
  - last_touch: 100% credit to last interaction
  - linear: Equal credit across all touchpoints
  - time_decay: More credit to touchpoints closer to conversion
  - position_based: Weighted credit (typically 40/20/40 for first/middle/last)
  - data_driven: ML-based attribution (future feature)
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @model_types [
    "first_touch",
    "last_touch",
    "linear",
    "time_decay",
    "position_based",
    "data_driven"
  ]

  @default_lookback_days 30
  @default_time_decay_halflife 7

  schema "qusto_attribution_models" do
    field :name, :string
    field :model_type, :string
    field :lookback_window_days, :integer, default: @default_lookback_days
    field :position_weights, :map
    field :time_decay_halflife, :integer, default: @default_time_decay_halflife
    field :is_default, :boolean, default: false
    field :is_active, :boolean, default: true

    belongs_to :site, Plausible.Site

    timestamps()
  end

  def model_types, do: @model_types

  def changeset(model \\ %__MODULE__{}, attrs) do
    model
    |> cast(attrs, [
      :name,
      :model_type,
      :lookback_window_days,
      :position_weights,
      :time_decay_halflife,
      :is_default,
      :is_active,
      :site_id
    ])
    |> validate_required([:name, :model_type, :site_id])
    |> validate_inclusion(:model_type, @model_types)
    |> validate_number(:lookback_window_days, greater_than: 0, less_than_or_equal_to: 365)
    |> validate_number(:time_decay_halflife, greater_than: 0, less_than_or_equal_to: 90)
    |> validate_position_weights()
    |> unique_constraint([:site_id, :name])
    |> unique_constraint(:site_id,
      name: :one_default_attribution_model_per_site,
      message: "already has a default attribution model"
    )
  end

  defp validate_position_weights(changeset) do
    model_type = get_field(changeset, :model_type)
    weights = get_field(changeset, :position_weights)

    cond do
      model_type == "position_based" and is_nil(weights) ->
        add_error(changeset, :position_weights, "is required for position_based model")

      model_type == "position_based" and not valid_position_weights?(weights) ->
        add_error(
          changeset,
          :position_weights,
          "must have 'first', 'middle', and 'last' keys that sum to 1.0"
        )

      true ->
        changeset
    end
  end

  defp valid_position_weights?(weights) when is_map(weights) do
    first = Map.get(weights, "first") || Map.get(weights, :first)
    middle = Map.get(weights, "middle") || Map.get(weights, :middle)
    last = Map.get(weights, "last") || Map.get(weights, :last)

    is_number(first) and is_number(middle) and is_number(last) and
      abs(first + middle + last - 1.0) < 0.01
  end

  defp valid_position_weights?(_), do: false

  @doc """
  Returns the default position-based weights (40/20/40).
  """
  def default_position_weights do
    %{"first" => 0.4, "middle" => 0.2, "last" => 0.4}
  end
end
