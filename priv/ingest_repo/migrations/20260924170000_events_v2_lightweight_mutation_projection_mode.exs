defmodule Plausible.IngestRepo.Migrations.EventsV2LightweightMutationProjectionMode do
  use Ecto.Migration

  import Plausible.MigrationUtils

  @on_cluster on_cluster_statement("events_v2")

  def up do
    # Qusto projections on events_v2 make ClickHouse refuse lightweight DELETE
    # unless this MergeTree setting is rebuild (query-level settings are ignored).
    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    MODIFY SETTING lightweight_mutation_projection_mode='rebuild'
    """
  end

  def down do
    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    MODIFY SETTING lightweight_mutation_projection_mode='throw'
    """
  end
end
