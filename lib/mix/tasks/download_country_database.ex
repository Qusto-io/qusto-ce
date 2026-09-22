defmodule Mix.Tasks.DownloadCountryDatabase do
  @moduledoc """
  This task downloads the Country Lite database from DB-IP for self-hosted or development purposes.
  Plausible Cloud runs a paid version of DB-IP with more detailed geolocation data.
  """

  use Mix.Task
  use Plausible.Repo
  require Logger

  @output_path "priv/geodb/dbip-country.mmdb.gz"
  @download_opts [timeout: 120_000, recv_timeout: 120_000]
  @max_attempts 3

  # coveralls-ignore-start

  def run(_) do
    Application.ensure_all_started(:httpoison)
    Application.ensure_all_started(:timex)

    if skip_download?() do
      Logger.notice("Country database already present at #{@output_path}, skipping download")
    else
      download_and_save()
    end
  end

  defp skip_download?() do
    case File.stat(@output_path) do
      {:ok, %File.Stat{size: size}} when size > 0 -> true
      _ -> false
    end
  end

  defp download_and_save do
    this_month = Date.utc_today()
    last_month = Date.shift(this_month, month: -1)
    this_month = this_month |> Date.to_iso8601() |> binary_part(0, 7)
    last_month = last_month |> Date.to_iso8601() |> binary_part(0, 7)
    this_month_url = "https://download.db-ip.com/free/dbip-country-lite-#{this_month}.mmdb.gz"
    last_month_url = "https://download.db-ip.com/free/dbip-country-lite-#{last_month}.mmdb.gz"

    Logger.notice("Downloading #{this_month_url}")

    with {:ok, body} <- fetch_url(this_month_url),
         :ok <- write_body(body) do
      Logger.notice("Downloaded and saved the database successfully")
    else
      {:error, :not_found} ->
        Logger.warning("Got 404 for #{this_month_url}, trying #{last_month_url}")

        case fetch_url(last_month_url) do
          {:ok, body} ->
            write_body(body)
            Logger.notice("Downloaded and saved the database successfully")

          {:error, reason} ->
            Mix.raise("Unable to download country database: #{inspect(reason)}")
        end

      {:error, reason} ->
        Mix.raise("Unable to download country database: #{inspect(reason)}")
    end
  end

  defp fetch_url(url) do
    fetch_url(url, 1)
  end

  defp fetch_url(url, attempt) when attempt > @max_attempts do
    {:error, :max_attempts_exceeded}
  end

  defp fetch_url(url, attempt) do
    case HTTPoison.get(url, [], @download_opts) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status_code: 404}} ->
        {:error, :not_found}

      {:ok, response} ->
        Logger.warning(
          "Unexpected response downloading #{url} (attempt #{attempt}/#{@max_attempts}): #{inspect(response.status_code)}"
        )

        retry_fetch(url, attempt)

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.warning(
          "Failed downloading #{url} (attempt #{attempt}/#{@max_attempts}): #{inspect(reason)}"
        )

        retry_fetch(url, attempt)
    end
  end

  defp retry_fetch(url, attempt) do
    Process.sleep(attempt * 2_000)
    fetch_url(url, attempt + 1)
  end

  defp write_body(body) do
    File.mkdir_p("priv/geodb")
    File.write!(@output_path, body)
    :ok
  end
end
