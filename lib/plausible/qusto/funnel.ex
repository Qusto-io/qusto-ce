defmodule Plausible.Qusto.Funnel do
  @moduledoc """
  Schema for Qusto-specific funnel definitions with e-commerce support.

  Funnels define a sequence of steps that users follow towards a conversion.
  Unlike the basic EE funnels, Qusto funnels support:
  - Multiple funnel types (ecommerce, custom, form)
  - Flexible step matching (event names, URL patterns, or both)
  - Configurable conversion windows
  - Strict vs. non-strict ordering
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Plausible.Qusto.FunnelStep

  @type t() :: %__MODULE__{}

  @funnel_types ["ecommerce", "custom", "form"]
  # 30 days
  @default_window_minutes 43_200

  schema "qusto_funnels" do
    field :name, :string
    field :description, :string
    field :funnel_type, :string, default: "custom"
    field :is_ecommerce_default, :boolean, default: false
    field :window_minutes, :integer, default: @default_window_minutes
    field :strict_order, :boolean, default: true

    belongs_to :site, Plausible.Site

    has_many :steps, FunnelStep,
      preload_order: [asc: :step_order],
      on_replace: :delete

    timestamps()
  end

  def funnel_types, do: @funnel_types

  def changeset(funnel \\ %__MODULE__{}, attrs \\ %{}) do
    funnel
    |> cast(attrs, [
      :name,
      :description,
      :funnel_type,
      :is_ecommerce_default,
      :window_minutes,
      :strict_order,
      :site_id
    ])
    |> validate_required([:name, :site_id, :funnel_type])
    |> validate_inclusion(:funnel_type, @funnel_types)
    # Max 1 year
    |> validate_number(:window_minutes, greater_than: 0, less_than_or_equal_to: 525_600)
    |> unique_constraint([:site_id, :name])
    |> cast_assoc(:steps, with: &FunnelStep.changeset/2)
    |> validate_length(:steps, min: 2, max: 10)
  end

  @doc """
  Creates a changeset for a new funnel with steps.
  """
  def create_changeset(attrs, site) do
    %__MODULE__{site_id: site.id}
    |> changeset(attrs)
  end
end
