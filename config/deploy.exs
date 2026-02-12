import Config

# Deployment-specific configuration for combining public + private code
# This file is only used in the deploy-production branch

# Load proprietary modules from submodule if available
qusto_ecommerce_path = System.get_env("QUSTO_ECOMMERCE_PATH") || "modules/qusto-ecommerce"
qusto_ecommerce_enabled = System.get_env("QUSTO_ECOMMERCE_ENABLED") == "true"

if qusto_ecommerce_enabled and File.exists?(Path.join(qusto_ecommerce_path, "elixir-modules")) do
  # Add proprietary Elixir modules to code paths
  Code.append_path(Path.join(qusto_ecommerce_path, "elixir-modules"))

  # Enable proprietary features
  config :plausible,
    qusto_ecommerce_enabled: true,
    qusto_ecommerce_path: qusto_ecommerce_path,
    qusto_ecommerce_url: System.get_env("QUSTO_ECOMMERCE_URL") || "http://localhost:8085"

  IO.puts("✓ Qusto E-commerce modules loaded from: #{qusto_ecommerce_path}")
  IO.puts("✓ E-commerce API URL: #{config[:plausible][:qusto_ecommerce_url]}")
else
  # Running CE without proprietary modules
  config :plausible,
    qusto_ecommerce_enabled: false

  if qusto_ecommerce_enabled do
    IO.warn("⚠ QUSTO_ECOMMERCE_ENABLED=true but modules not found at: #{qusto_ecommerce_path}")
  else
    IO.puts("ℹ Running Qusto CE without e-commerce modules")
  end
end

# Database configuration for deployment
config :plausible, Plausible.Repo,
  # Standard connection settings
  pool_size: String.to_integer(System.get_env("DATABASE_POOL_SIZE") || "10"),
  # Use SSL if required
  ssl: System.get_env("DATABASE_SSL") == "true"

config :plausible, Plausible.IngestRepo,
  pool_size: String.to_integer(System.get_env("CLICKHOUSE_POOL_SIZE") || "5")

# Feature flags for deployment
config :plausible,
  # Enable all enterprise features if e-commerce is available
  enable_revenue_goals: qusto_ecommerce_enabled,
  enable_funnels: true,  # Basic funnels always available
  enable_props: true,
  enable_conversions: qusto_ecommerce_enabled

# Log level for production
config :logger, level: String.to_atom(System.get_env("LOG_LEVEL") || "info")
