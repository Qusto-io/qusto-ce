defmodule Plausible.IngestRepo.Migrations.CreateQustoFunnelEvents do
  use Ecto.Migration

  import Plausible.MigrationUtils

  def up do
    on_cluster = on_cluster_statement("qusto_funnel_events")
    table_settings = table_settings_expr()

    execute """
    CREATE TABLE IF NOT EXISTS qusto_funnel_events #{on_cluster}
    (
        site_id UInt64,
        funnel_id UInt64,
        user_id UInt64,
        session_id UInt64,

        step_name LowCardinality(String),
        step_order UInt8,
        timestamp DateTime CODEC(Delta(4), LZ4),

        -- E-commerce context
        product_id LowCardinality(String) DEFAULT '',
        product_name String DEFAULT '' CODEC(ZSTD(3)),
        product_category LowCardinality(String) DEFAULT '',
        revenue Nullable(Decimal64(3)),

        -- Attribution context
        referrer_source LowCardinality(String) DEFAULT '',
        utm_campaign String DEFAULT '' CODEC(ZSTD(3)),
        ai_referral_source LowCardinality(String) DEFAULT ''
    )
    ENGINE = MergeTree()
    PARTITION BY toYYYYMM(timestamp)
    ORDER BY (site_id, funnel_id, user_id, timestamp)
    #{table_settings}
    TTL timestamp + INTERVAL 13 MONTH
    """
  end

  def down do
    on_cluster = on_cluster_statement("qusto_funnel_events")

    execute """
    DROP TABLE IF EXISTS qusto_funnel_events #{on_cluster}
    """
  end
end
