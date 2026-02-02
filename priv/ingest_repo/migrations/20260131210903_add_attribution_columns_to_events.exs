defmodule Plausible.IngestRepo.Migrations.AddAttributionColumnsToEvents do
  use Ecto.Migration

  import Plausible.MigrationUtils

  @on_cluster on_cluster_statement("events_v2")

  def up do
    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    ADD COLUMN IF NOT EXISTS funnel_id UInt64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS funnel_step UInt8 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS conversion_id UUID DEFAULT generateUUIDv4(),
    ADD COLUMN IF NOT EXISTS conversion_value Nullable(Decimal64(3)),
    ADD COLUMN IF NOT EXISTS touchpoint_order UInt8 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS consent_level LowCardinality(String) DEFAULT 'minimal'
    """
  end

  def down do
    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    DROP COLUMN IF EXISTS funnel_id,
    DROP COLUMN IF EXISTS funnel_step,
    DROP COLUMN IF EXISTS conversion_id,
    DROP COLUMN IF EXISTS conversion_value,
    DROP COLUMN IF EXISTS touchpoint_order,
    DROP COLUMN IF EXISTS consent_level
    """
  end
end
