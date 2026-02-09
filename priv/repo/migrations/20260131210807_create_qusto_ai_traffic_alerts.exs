defmodule Plausible.Repo.Migrations.CreateQustoAiTrafficAlerts do
  use Ecto.Migration

  def change do
    create table(:qusto_ai_traffic_alerts) do
      add :site_id, references(:sites, on_delete: :delete_all), null: false
      add :alert_type, :text, null: false
      add :ai_source, :text
      add :threshold_percent, :decimal, precision: 5, scale: 2
      add :comparison_period_days, :integer, default: 7, null: false
      add :notification_email, :text
      add :notification_webhook, :text
      add :is_active, :boolean, default: true, null: false

      timestamps(updated_at: false)
    end

    create index(:qusto_ai_traffic_alerts, [:site_id])
    create index(:qusto_ai_traffic_alerts, [:alert_type])
    create index(:qusto_ai_traffic_alerts, [:is_active])
  end
end
