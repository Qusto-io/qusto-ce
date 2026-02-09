defmodule Plausible.Repo.Migrations.CreateQustoFunnelPresets do
  use Ecto.Migration

  def change do
    create table(:qusto_funnel_presets) do
      add :name, :text, null: false
      add :description, :text
      add :platform, :text
      add :steps_config, :jsonb, null: false
      add :is_active, :boolean, default: true, null: false

      timestamps(updated_at: false)
    end

    create unique_index(:qusto_funnel_presets, [:name])
  end
end
