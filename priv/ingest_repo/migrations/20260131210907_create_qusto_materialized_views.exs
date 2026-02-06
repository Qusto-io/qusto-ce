defmodule Plausible.IngestRepo.Migrations.CreateQustoMaterializedViews do
  use Ecto.Migration

  import Plausible.MigrationUtils

  def up do
    # Skip materialized views in test environments to avoid dependency issues
    # Check both the runtime environment string and Mix environment atom
    env = Application.get_env(:plausible, :environment)

    if env == "test" or env == :test do
      :ok
    else
      create_materialized_views()
    end
  end

  defp create_materialized_views do
    on_cluster = on_cluster_statement("events_v2")

    # AI Traffic Daily Materialized View
    execute """
    CREATE MATERIALIZED VIEW IF NOT EXISTS qusto_ai_traffic_daily_mv #{on_cluster}
    ENGINE = SummingMergeTree()
    PARTITION BY toYYYYMM(toDate(timestamp))
    ORDER BY (site_id, toDate(timestamp), ai_referral_source)
    AS SELECT
        site_id,
        toDate(timestamp) as date,
        ai_referral_source,

        uniqState(user_id) as visitors_state,
        uniqState(session_id) as sessions_state,
        count() as pageviews,

        sumIf(revenue_source_amount, name = 'Purchase') as revenue,
        uniqIf(user_id, name = 'Purchase') as conversions,

        avgState(engagement_time) as avg_engagement_state
    FROM events_v2
    WHERE ai_referral_source != ''
    GROUP BY site_id, toDate(timestamp), ai_referral_source
    """

    # Funnel Conversion Daily Materialized View
    execute """
    CREATE MATERIALIZED VIEW IF NOT EXISTS qusto_funnel_conversions_daily_mv #{on_cluster}
    ENGINE = SummingMergeTree()
    PARTITION BY toYYYYMM(toDate(timestamp))
    ORDER BY (site_id, funnel_id, toDate(timestamp))
    AS SELECT
        site_id,
        funnel_id,
        toDate(timestamp) as date,

        -- Step counts using windowFunnel
        uniqState(user_id) as users_state,

        -- Step completion counts
        countIf(funnel_step = 1) as step_1_count,
        countIf(funnel_step = 2) as step_2_count,
        countIf(funnel_step = 3) as step_3_count,
        countIf(funnel_step = 4) as step_4_count,
        countIf(funnel_step = 5) as step_5_count,
        countIf(funnel_step = 6) as step_6_count,
        countIf(funnel_step = 7) as step_7_count,
        countIf(funnel_step = 8) as step_8_count,

        -- Revenue by step
        sumIf(revenue_source_amount, funnel_step = 1) as step_1_revenue,
        sumIf(revenue_source_amount, funnel_step >= 5) as final_step_revenue

    FROM events_v2
    WHERE funnel_id > 0
    GROUP BY site_id, funnel_id, toDate(timestamp)
    """

    # E-commerce Funnel Metrics Materialized View
    execute """
    CREATE MATERIALIZED VIEW IF NOT EXISTS qusto_ecommerce_funnel_mv #{on_cluster}
    ENGINE = SummingMergeTree()
    PARTITION BY toYYYYMM(toDate(timestamp))
    ORDER BY (site_id, toDate(timestamp), product_category)
    AS SELECT
        site_id,
        toDate(timestamp) as date,
        product_category,

        -- Standard e-commerce funnel
        countIf(name = 'Product View') as product_views,
        countIf(name = 'Add to Cart') as add_to_carts,
        countIf(name = 'Begin Checkout') as checkouts,
        countIf(name = 'Purchase') as purchases,

        -- Revenue
        sumIf(revenue_source_amount, name = 'Purchase') as revenue,

        -- Unique users per stage
        uniqIf(user_id, name = 'Product View') as unique_viewers,
        uniqIf(user_id, name = 'Purchase') as unique_purchasers

    FROM events_v2
    WHERE name IN ('Product View', 'Add to Cart', 'Begin Checkout', 'Purchase')
    GROUP BY site_id, toDate(timestamp), product_category
    """

    # Attribution Conversions Materialized View
    execute """
    CREATE MATERIALIZED VIEW IF NOT EXISTS qusto_attribution_daily_mv #{on_cluster}
    ENGINE = SummingMergeTree()
    PARTITION BY toYYYYMM(toDate(timestamp))
    ORDER BY (site_id, toDate(timestamp), first_touch_source, last_touch_source)
    AS SELECT
        site_id,
        toDate(timestamp) as date,
        first_touch_source,
        first_touch_medium,
        last_touch_source,
        last_touch_medium,

        count() as conversions,
        sum(revenue) as total_revenue,
        avg(days_to_conversion) as avg_days_to_conversion,
        avg(touchpoint_count) as avg_touchpoints

    FROM qusto_conversions
    GROUP BY site_id, toDate(timestamp), first_touch_source, first_touch_medium, last_touch_source, last_touch_medium
    """
  end

  def down do
    on_cluster = on_cluster_statement("events_v2")

    execute "DROP VIEW IF EXISTS qusto_ai_traffic_daily_mv #{on_cluster}"
    execute "DROP VIEW IF EXISTS qusto_funnel_conversions_daily_mv #{on_cluster}"
    execute "DROP VIEW IF EXISTS qusto_ecommerce_funnel_mv #{on_cluster}"
    execute "DROP VIEW IF EXISTS qusto_attribution_daily_mv #{on_cluster}"
  end
end
