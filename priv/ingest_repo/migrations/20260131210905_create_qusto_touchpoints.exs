defmodule Plausible.IngestRepo.Migrations.CreateQustoTouchpoints do
  use Ecto.Migration

  import Plausible.MigrationUtils

  def up do
    on_cluster = on_cluster_statement("qusto_touchpoints")
    table_settings = table_settings_expr()

    execute """
    CREATE TABLE IF NOT EXISTS qusto_touchpoints #{on_cluster}
    (
        site_id UInt64,
        user_id UInt64,
        session_id UInt64,
        timestamp DateTime CODEC(Delta(4), LZ4),

        -- Source info
        referrer_source LowCardinality(String),
        referrer_medium LowCardinality(String),
        utm_source String DEFAULT '' CODEC(ZSTD(3)),
        utm_medium String DEFAULT '' CODEC(ZSTD(3)),
        utm_campaign String DEFAULT '' CODEC(ZSTD(3)),
        utm_content String DEFAULT '' CODEC(ZSTD(3)),
        utm_term String DEFAULT '' CODEC(ZSTD(3)),

        -- AI search tracking (ACCELERATED PRIORITY)
        ai_referral_source LowCardinality(String) DEFAULT '',

        -- Click IDs
        click_id_param LowCardinality(String) DEFAULT '',
        click_id_value String DEFAULT '' CODEC(ZSTD(3)),

        -- Touchpoint sequence
        touchpoint_order UInt8,
        days_since_first_touch UInt16,

        -- Landing page
        landing_page String CODEC(ZSTD(3)),

        -- Device/geo context
        device_type LowCardinality(String),
        country_code FixedString(2)
    )
    ENGINE = MergeTree()
    PARTITION BY toYYYYMM(timestamp)
    ORDER BY (site_id, user_id, timestamp)
    #{table_settings}
    TTL timestamp + INTERVAL 13 MONTH
    """
  end

  def down do
    on_cluster = on_cluster_statement("qusto_touchpoints")

    execute """
    DROP TABLE IF EXISTS qusto_touchpoints #{on_cluster}
    """
  end
end
