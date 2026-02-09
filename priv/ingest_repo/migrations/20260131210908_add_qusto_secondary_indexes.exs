defmodule Plausible.IngestRepo.Migrations.AddQustoSecondaryIndexes do
  use Ecto.Migration

  import Plausible.MigrationUtils

  @on_cluster on_cluster_statement("events_v2")

  def up do
    # Add secondary indexes for common query patterns on events_v2
    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    ADD INDEX IF NOT EXISTS idx_ai_referral ai_referral_source TYPE set(100) GRANULARITY 4
    """

    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    ADD INDEX IF NOT EXISTS idx_product_category product_category TYPE set(1000) GRANULARITY 4
    """

    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    ADD INDEX IF NOT EXISTS idx_funnel_id funnel_id TYPE minmax GRANULARITY 4
    """

    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    ADD INDEX IF NOT EXISTS idx_order_id order_id TYPE bloom_filter() GRANULARITY 4
    """

    # Add projection for AI search queries (optimized ordering)
    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    ADD PROJECTION IF NOT EXISTS qusto_ai_search_proj
    (
        SELECT
            site_id,
            toDate(timestamp) as date,
            ai_referral_source,
            user_id,
            session_id,
            name,
            revenue_source_amount
        ORDER BY (site_id, toDate(timestamp), ai_referral_source)
    )
    """

    # Add projection for e-commerce queries
    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    ADD PROJECTION IF NOT EXISTS qusto_ecommerce_proj
    (
        SELECT
            site_id,
            toDate(timestamp) as date,
            product_category,
            name,
            user_id,
            revenue_source_amount,
            product_id
        ORDER BY (site_id, toDate(timestamp), product_category, name)
    )
    """
  end

  def down do
    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    DROP INDEX IF EXISTS idx_ai_referral
    """

    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    DROP INDEX IF EXISTS idx_product_category
    """

    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    DROP INDEX IF EXISTS idx_funnel_id
    """

    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    DROP INDEX IF EXISTS idx_order_id
    """

    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    DROP PROJECTION IF EXISTS qusto_ai_search_proj
    """

    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    DROP PROJECTION IF EXISTS qusto_ecommerce_proj
    """
  end
end
