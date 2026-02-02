defmodule Plausible.Repo.Migrations.CreateQustoFunnels do
  use Ecto.Migration

  def change do
    create table(:qusto_funnels) do
      add :site_id, references(:sites, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :description, :text
      add :funnel_type, :text, null: false, default: "custom"
      add :is_ecommerce_default, :boolean, default: false, null: false
      add :window_minutes, :integer, default: 43200, null: false
      add :strict_order, :boolean, default: true, null: false

      timestamps()
    end

    create index(:qusto_funnels, [:site_id])
    create index(:qusto_funnels, [:funnel_type])
    create unique_index(:qusto_funnels, [:site_id, :name])
  end
end
