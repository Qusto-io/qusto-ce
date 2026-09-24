defmodule Plausible.IngestRepo.Migrations.ReapplyEventsV2LightweightMutationProjectionMode do
  @moduledoc """
  Re-applies table-level `lightweight_mutation_projection_mode` when ClickHouse
  is upgraded to 25.1+ after the original migration no-opped on 24.3 prod.
  """

  use Ecto.Migration

  import Plausible.MigrationUtils

  @on_cluster on_cluster_statement("events_v2")
  @min_ch_version {25, 1, 0}

  def up do
    if clickhouse_version_at_least?(@min_ch_version) do
      execute """
      ALTER TABLE events_v2
      #{@on_cluster}
      MODIFY SETTING lightweight_mutation_projection_mode='rebuild'
      """
    end
  end

  def down do
    if clickhouse_version_at_least?(@min_ch_version) do
      execute """
      ALTER TABLE events_v2
      #{@on_cluster}
      MODIFY SETTING lightweight_mutation_projection_mode='throw'
      """
    end
  end
end
