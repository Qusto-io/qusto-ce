defmodule Plausible.Repo.Migrations.CreateQustoAiReferrers do
  use Ecto.Migration

  def change do
    create table(:qusto_ai_referrers) do
      add :name, :text, null: false
      add :display_name, :text, null: false
      add :referrer_patterns, {:array, :text}, null: false
      add :utm_patterns, {:array, :text}
      add :category, :text, default: "ai_search", null: false
      add :is_tracked, :boolean, default: true, null: false
      add :color_hex, :text
      add :icon_url, :text

      timestamps()
    end

    create unique_index(:qusto_ai_referrers, [:name])
    create index(:qusto_ai_referrers, [:category])
  end
end
