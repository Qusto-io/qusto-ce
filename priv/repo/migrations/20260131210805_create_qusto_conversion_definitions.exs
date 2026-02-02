defmodule Plausible.Repo.Migrations.CreateQustoConversionDefinitions do
  use Ecto.Migration

  def change do
    create table(:qusto_conversion_definitions) do
      add :site_id, references(:sites, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :event_name, :text, null: false
      add :has_revenue, :boolean, default: false, null: false
      add :default_value, :decimal, precision: 10, scale: 2
      add :filters, :jsonb, default: "{}", null: false
      add :is_active, :boolean, default: true, null: false

      timestamps(updated_at: false)
    end

    create index(:qusto_conversion_definitions, [:site_id])
    create unique_index(:qusto_conversion_definitions, [:site_id, :name])
  end
end
