defmodule Plausible.IngestRepo.Migrations.AddAiColumnsToEvents do
  use Ecto.Migration

  import Plausible.MigrationUtils

  @on_cluster_events on_cluster_statement("events_v2")
  @on_cluster_sessions on_cluster_statement("sessions_v2")

  def up do
    # Add AI tracking columns to events_v2
    execute """
    ALTER TABLE events_v2
    #{@on_cluster_events}
    ADD COLUMN IF NOT EXISTS ai_referral_source LowCardinality(String) DEFAULT '',
    ADD COLUMN IF NOT EXISTS ai_detected_intent LowCardinality(String) DEFAULT ''
    """

    # Add AI tracking columns to sessions_v2
    execute """
    ALTER TABLE sessions_v2
    #{@on_cluster_sessions}
    ADD COLUMN IF NOT EXISTS ai_referral_source LowCardinality(String) DEFAULT '',
    ADD COLUMN IF NOT EXISTS is_ai_referred UInt8 DEFAULT 0
    """
  end

  def down do
    execute """
    ALTER TABLE events_v2
    #{@on_cluster_events}
    DROP COLUMN IF EXISTS ai_referral_source,
    DROP COLUMN IF EXISTS ai_detected_intent
    """

    execute """
    ALTER TABLE sessions_v2
    #{@on_cluster_sessions}
    DROP COLUMN IF EXISTS ai_referral_source,
    DROP COLUMN IF EXISTS is_ai_referred
    """
  end
end
