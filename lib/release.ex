defmodule Plausible.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix installed.

  This module provides functions for running migrations and managing the database
  in a production environment where Mix is not available.

  ## Usage

  Run migrations on boot by setting environment variable:
  ```bash
  MIGRATE_ON_BOOT=true /app/bin/plausible start
  ```

  Or run migrations manually:
  ```bash
  /app/bin/plausible eval "Plausible.Release.migrate()"
  ```
  """
  require Logger

  @app :plausible

  @doc """
  Runs all pending migrations for the application.

  This function loads the application, fetches all configured repositories,
  and runs migrations for each one.

  ## Examples

      iex> Plausible.Release.migrate()
      :ok

  """
  def migrate do
    load_app()
    Logger.info("🔄 Running migrations for #{@app}")

    for repo <- repos() do
      Logger.info("Running migrations for #{inspect(repo)}")
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    Logger.info("✅ Migrations completed successfully")
    :ok
  end

  @doc """
  Rolls back the repository to a specific version.

  ## Parameters

    - repo: The repository module to rollback
    - version: The version number to rollback to

  ## Examples

      iex> Plausible.Release.rollback(Plausible.Repo, 20210101000000)
      :ok

  """
  def rollback(repo, version) when is_integer(version) do
    load_app()
    Logger.info("Rolling back #{inspect(repo)} to version #{version}")
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
    Logger.info("✅ Rollback completed")
    :ok
  end

  @doc """
  Creates the database for all configured repositories.

  This is useful for initial setup when the database doesn't exist yet.

  ## Examples

      iex> Plausible.Release.create_db()
      :ok

  """
  def create_db do
    load_app()
    Logger.info("Creating databases for #{@app}")

    for repo <- repos() do
      case ensure_repo_created(repo) do
        :ok -> :ok
        {:error, term} -> Logger.error("Failed to create database for #{inspect(repo)}: #{inspect(term)}")
      end
    end

    Logger.info("✅ Database creation completed")
    :ok
  end

  @doc """
  Drops the database for all configured repositories.

  ⚠️ WARNING: This will delete all data! Use with extreme caution.

  ## Examples

      iex> Plausible.Release.drop_db()
      :ok

  """
  def drop_db do
    load_app()
    Logger.warn("⚠️  Dropping databases for #{@app}")

    for repo <- repos() do
      case repo.__adapter__.storage_down(repo.config) do
        :ok ->
          Logger.info("Database dropped for #{inspect(repo)}")
          :ok

        {:error, :already_down} ->
          Logger.info("Database already dropped for #{inspect(repo)}")
          :ok

        {:error, term} ->
          Logger.error("Failed to drop database for #{inspect(repo)}: #{inspect(term)}")
          {:error, term}
      end
    end

    Logger.info("✅ Database drop completed")
    :ok
  end

  @doc """
  Seeds the database with initial data.

  This function runs the seeds script if it exists.

  ## Examples

      iex> Plausible.Release.seed()
      :ok

  """
  def seed do
    load_app()
    Logger.info("🌱 Seeding database for #{@app}")

    seeds_file = Application.app_dir(@app, "priv/repo/seeds.exs")

    if File.exists?(seeds_file) do
      Code.eval_file(seeds_file)
      Logger.info("✅ Seeding completed")
    else
      Logger.info("ℹ️  No seeds file found at #{seeds_file}")
    end

    :ok
  end

  # Private Functions

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp ensure_repo_created(repo) do
    Logger.info("Ensuring database exists for #{inspect(repo)}")

    case repo.__adapter__.storage_up(repo.config) do
      :ok ->
        Logger.info("✅ Database created successfully for #{inspect(repo)}")
        :ok

      {:error, :already_up} ->
        Logger.info("ℹ️  Database already exists for #{inspect(repo)}")
        :ok

      {:error, term} ->
        Logger.error("❌ Failed to create database for #{inspect(repo)}: #{inspect(term)}")
        {:error, term}
    end
  end

  defp load_app do
    Application.load(@app)
  end
end
