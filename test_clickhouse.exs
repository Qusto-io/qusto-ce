#!/usr/bin/env elixir
# Test ClickHouse connection for Qusto/Plausible
require Logger

Logger.configure(level: :info)

Logger.info("=" |> String.duplicate(60))
Logger.info("Testing ClickHouse Connection")
Logger.info("=" |> String.duplicate(60))

# Test 1: Basic connectivity
Logger.info("\n[Test 1] Testing basic connectivity...")

case Plausible.ClickhouseRepo.query("SELECT 1 as test") do
  {:ok, %{rows: [[1]]}} ->
    Logger.info("✅ SUCCESS: Basic query executed successfully")

  {:ok, result} ->
    Logger.info("⚠️  PARTIAL: Query succeeded but unexpected result")
    Logger.info("Result: #{inspect(result)}")

  {:error, reason} ->
    Logger.error("❌ FAILED: ClickHouse connection failed!")
    Logger.error("Reason: #{inspect(reason)}")
end

# Test 2: Version check
Logger.info("\n[Test 2] Checking ClickHouse version...")

case Plausible.ClickhouseRepo.query("SELECT version() as version") do
  {:ok, %{rows: [[version]]}} ->
    Logger.info("✅ SUCCESS: ClickHouse version #{version}")

  {:error, reason} ->
    Logger.error("❌ FAILED: Could not get version")
    Logger.error("Reason: #{inspect(reason)}")
end

# Test 3: List databases
Logger.info("\n[Test 3] Listing available databases...")

case Plausible.ClickhouseRepo.query("SHOW DATABASES") do
  {:ok, %{rows: rows}} ->
    databases = Enum.map(rows, fn [db] -> db end)
    Logger.info("✅ SUCCESS: Found #{length(databases)} databases")

    Enum.each(databases, fn db ->
      marker = if db == "plausible_events_db", do: "  ➜ ", else: "    "
      Logger.info("#{marker}#{db}")
    end)

    if "plausible_events_db" in databases do
      Logger.info("✅ Target database 'plausible_events_db' exists")
    else
      Logger.warning("⚠️  Target database 'plausible_events_db' not found!")
    end

  {:error, reason} ->
    Logger.error("❌ FAILED: Could not list databases")
    Logger.error("Reason: #{inspect(reason)}")
end

# Test 4: Check repository configuration
Logger.info("\n[Test 4] Checking repository configuration...")

config = Application.get_env(:plausible, Plausible.ClickhouseRepo)
Logger.info("Configuration:")
Logger.info("  URL: #{config[:url]}")
Logger.info("  Queue Target: #{config[:queue_target]}")
Logger.info("  Queue Interval: #{config[:queue_interval]}")

# Test 5: Test IngestRepo configuration
Logger.info("\n[Test 5] Checking IngestRepo configuration...")

ingest_config = Application.get_env(:plausible, Plausible.IngestRepo)
Logger.info("IngestRepo Configuration:")
Logger.info("  URL: #{ingest_config[:url]}")
Logger.info("  Pool Size: #{ingest_config[:pool_size]}")
Logger.info("  Flush Interval: #{ingest_config[:flush_interval_ms]}ms")
Logger.info("  Max Buffer Size: #{ingest_config[:max_buffer_size]} bytes")

Logger.info("\n" <> ("=" |> String.duplicate(60)))
Logger.info("ClickHouse Connection Test Complete")
Logger.info("=" |> String.duplicate(60))
