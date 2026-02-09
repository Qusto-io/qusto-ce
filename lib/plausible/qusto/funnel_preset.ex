defmodule Plausible.Qusto.FunnelPreset do
  @moduledoc """
  Schema for pre-built funnel templates.

  Presets allow quick setup of common funnel configurations,
  particularly useful for e-commerce platforms like Shopify,
  WooCommerce, or generic SaaS applications.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @platforms ["shopify", "woocommerce", "generic", "saas", "magento", "bigcommerce"]

  schema "qusto_funnel_presets" do
    field :name, :string
    field :description, :string
    field :platform, :string
    field :steps_config, :map
    field :is_active, :boolean, default: true

    timestamps(updated_at: false)
  end

  def platforms, do: @platforms

  def changeset(preset \\ %__MODULE__{}, attrs) do
    preset
    |> cast(attrs, [:name, :description, :platform, :steps_config, :is_active])
    |> validate_required([:name, :steps_config])
    |> validate_inclusion(:platform, @platforms)
    |> validate_steps_config()
    |> unique_constraint(:name)
  end

  defp validate_steps_config(changeset) do
    case get_field(changeset, :steps_config) do
      nil ->
        changeset

      steps when is_map(steps) ->
        if Map.has_key?(steps, "steps") or Map.has_key?(steps, :steps) do
          changeset
        else
          add_error(changeset, :steps_config, "must contain a 'steps' key")
        end

      _ ->
        add_error(changeset, :steps_config, "must be a map")
    end
  end
end
