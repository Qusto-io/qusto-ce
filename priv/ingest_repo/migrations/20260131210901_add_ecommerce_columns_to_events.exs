defmodule Plausible.IngestRepo.Migrations.AddEcommerceColumnsToEvents do
  use Ecto.Migration

  import Plausible.MigrationUtils

  @on_cluster on_cluster_statement("events_v2")

  def up do
    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    ADD COLUMN IF NOT EXISTS product_id LowCardinality(String) DEFAULT '',
    ADD COLUMN IF NOT EXISTS product_name String DEFAULT '',
    ADD COLUMN IF NOT EXISTS product_category LowCardinality(String) DEFAULT '',
    ADD COLUMN IF NOT EXISTS product_price Nullable(Decimal64(3)),
    ADD COLUMN IF NOT EXISTS product_quantity UInt16 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS product_sku String DEFAULT '',
    ADD COLUMN IF NOT EXISTS order_id String DEFAULT '',
    ADD COLUMN IF NOT EXISTS cart_total Nullable(Decimal64(3)),
    ADD COLUMN IF NOT EXISTS cart_item_count UInt8 DEFAULT 0
    """
  end

  def down do
    execute """
    ALTER TABLE events_v2
    #{@on_cluster}
    DROP COLUMN IF EXISTS product_id,
    DROP COLUMN IF EXISTS product_name,
    DROP COLUMN IF EXISTS product_category,
    DROP COLUMN IF EXISTS product_price,
    DROP COLUMN IF EXISTS product_quantity,
    DROP COLUMN IF EXISTS product_sku,
    DROP COLUMN IF EXISTS order_id,
    DROP COLUMN IF EXISTS cart_total,
    DROP COLUMN IF EXISTS cart_item_count
    """
  end
end
