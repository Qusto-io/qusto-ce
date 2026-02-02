defmodule Plausible.Repo.Migrations.CreateQustoFunnelSteps do
  use Ecto.Migration

  def change do
    create table(:qusto_funnel_steps) do
      add :funnel_id, references(:qusto_funnels, on_delete: :delete_all), null: false
      add :step_order, :smallint, null: false
      add :name, :text, null: false
      add :event_name, :text
      add :url_pattern, :text
      add :match_type, :text, default: "event", null: false
      add :filters, :jsonb, default: "{}", null: false

      timestamps(updated_at: false)
    end

    create index(:qusto_funnel_steps, [:funnel_id])
    create unique_index(:qusto_funnel_steps, [:funnel_id, :step_order], name: :unique_funnel_step_order)
  end
end
