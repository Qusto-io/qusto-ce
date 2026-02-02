defmodule Plausible.Repo.Migrations.CreateQustoAttributionModels do
  use Ecto.Migration

  def change do
    create table(:qusto_attribution_models) do
      add :site_id, references(:sites, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :model_type, :text, null: false
      add :lookback_window_days, :integer, default: 30, null: false
      add :position_weights, :jsonb
      add :time_decay_halflife, :integer, default: 7, null: false
      add :is_default, :boolean, default: false, null: false
      add :is_active, :boolean, default: true, null: false

      timestamps()
    end

    create index(:qusto_attribution_models, [:site_id])
    create unique_index(:qusto_attribution_models, [:site_id, :name])

    # Partial unique index to ensure only one default model per site
    create unique_index(:qusto_attribution_models, [:site_id],
      where: "is_default = true",
      name: :one_default_attribution_model_per_site
    )
  end
end
