defmodule Plausible.Qusto.ConversionDefinition do
  @moduledoc """
  Schema for defining what counts as a conversion for attribution.

  Conversion definitions specify which events trigger attribution calculations
  and optionally track revenue values.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  schema "qusto_conversion_definitions" do
    field :name, :string
    field :event_name, :string
    field :has_revenue, :boolean, default: false
    field :default_value, :decimal
    field :filters, :map, default: %{}
    field :is_active, :boolean, default: true

    belongs_to :site, Plausible.Site

    timestamps(updated_at: false)
  end

  def changeset(definition \\ %__MODULE__{}, attrs) do
    definition
    |> cast(attrs, [
      :name,
      :event_name,
      :has_revenue,
      :default_value,
      :filters,
      :is_active,
      :site_id
    ])
    |> validate_required([:name, :event_name, :site_id])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:event_name, min: 1, max: 120)
    |> validate_number(:default_value, greater_than_or_equal_to: 0)
    |> validate_revenue_consistency()
    |> unique_constraint([:site_id, :name])
  end

  defp validate_revenue_consistency(changeset) do
    has_revenue = get_field(changeset, :has_revenue)
    default_value = get_field(changeset, :default_value)

    if has_revenue and is_nil(default_value) do
      # This is allowed - revenue can come from the event itself
      changeset
    else
      changeset
    end
  end
end
