defmodule Plausible.IngestRepo.Migrations.CreateQustoConversions do
  use Ecto.Migration

  import Plausible.MigrationUtils

  def up do
    on_cluster = on_cluster_statement("qusto_conversions")
    table_settings = table_settings_expr()

    execute """
    CREATE TABLE IF NOT EXISTS qusto_conversions #{on_cluster}
    (
        site_id UInt64,
        user_id UInt64,
        session_id UInt64,
        conversion_id UUID,
        timestamp DateTime CODEC(Delta(4), LZ4),

        -- Conversion details
        conversion_name LowCardinality(String),
        revenue Nullable(Decimal64(3)),
        currency FixedString(3) DEFAULT 'EUR',

        -- E-commerce details
        order_id String DEFAULT '' CODEC(ZSTD(3)),
        product_ids Array(String) DEFAULT [],

        -- First touch attribution
        first_touch_source LowCardinality(String) DEFAULT '',
        first_touch_medium LowCardinality(String) DEFAULT '',
        first_touch_campaign String DEFAULT '' CODEC(ZSTD(3)),
        first_touch_ai_source LowCardinality(String) DEFAULT '',

        -- Last touch attribution
        last_touch_source LowCardinality(String) DEFAULT '',
        last_touch_medium LowCardinality(String) DEFAULT '',
        last_touch_campaign String DEFAULT '' CODEC(ZSTD(3)),
        last_touch_ai_source LowCardinality(String) DEFAULT '',

        -- Journey metadata
        touchpoint_count UInt8,
        days_to_conversion UInt16,

        -- Consent level (affects attribution accuracy)
        consent_level LowCardinality(String) DEFAULT 'minimal'
    )
    ENGINE = MergeTree()
    PARTITION BY toYYYYMM(timestamp)
    ORDER BY (site_id, timestamp, conversion_id)
    #{table_settings}
    TTL timestamp + INTERVAL 25 MONTH
    """
  end

  def down do
    on_cluster = on_cluster_statement("qusto_conversions")

    execute """
    DROP TABLE IF EXISTS qusto_conversions #{on_cluster}
    """
  end
end
