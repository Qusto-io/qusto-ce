defmodule PlausibleWeb.Api.ProvisionController do
  @moduledoc """
  Writes the site row managed Qusto needs so CE ingest keeps events.

  This is not Plausible's sites API. It does not create teams, start trials,
  or call `Plausible.Sites.create/3`. It writes `sites` and `site_memberships`
  only, for team_id 1 and user_id 1, which is the production row those
  foreign keys already point at.
  """

  use PlausibleWeb, :controller

  require Logger

  alias Plausible.Repo

  @default_timezone "Europe/Berlin"

  def create(conn, params) do
    case gate(conn) do
      :disabled ->
        send_resp(conn, 404, "")

      :unauthorized ->
        send_resp(conn, 401, "")

      :ok ->
        with {:ok, domain} <- take_domain(params),
             {:ok, timezone} <- take_timezone(params),
             {:ok, _} <- insert_site(domain, timezone) do
          conn |> put_status(200) |> json(%{domain: domain})
        else
          :bad_domain ->
            send_resp(conn, 400, "")

          :bad_timezone ->
            send_resp(conn, 400, "")

          {:error, reason} ->
            Logger.error("provision create failed: #{inspect(reason)}")
            send_resp(conn, 500, "")
        end
    end
  end

  def delete(conn, %{"domain" => domain}) do
    case gate(conn) do
      :disabled ->
        send_resp(conn, 404, "")

      :unauthorized ->
        send_resp(conn, 401, "")

      :ok ->
        case take_domain(%{"domain" => domain}) do
          :bad_domain ->
            send_resp(conn, 400, "")

          {:ok, domain} ->
            case delete_site(domain) do
              {:ok, 0} ->
                send_resp(conn, 404, "")

              {:ok, _} ->
                send_resp(conn, 200, "")

              {:error, reason} ->
                Logger.error("provision delete failed: #{inspect(reason)}")
                send_resp(conn, 500, "")
            end
        end
    end
  end

  defp gate(conn) do
    case Application.get_env(:plausible, :provision_token) do
      token when is_binary(token) and token != "" ->
        if authorized?(conn, token), do: :ok, else: :unauthorized

      _ ->
        :disabled
    end
  end

  defp authorized?(conn, expected) do
    case bearer(conn) do
      given when is_binary(given) and byte_size(given) == byte_size(expected) ->
        Plug.Crypto.secure_compare(given, expected)

      _ ->
        false
    end
  end

  defp bearer(conn) do
    case get_req_header(conn, "authorization") do
      [value | _] ->
        case String.split(value, " ", parts: 2) do
          [scheme, token] ->
            if String.downcase(scheme) == "bearer", do: String.trim(token), else: nil

          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  defp take_domain(params) do
    domain = params |> Map.get("domain", "") |> to_string() |> String.trim()

    cond do
      domain == "" -> :bad_domain
      byte_size(domain) > 253 -> :bad_domain
      String.contains?(domain, [" ", "\n", "\r", "\t", "\0"]) -> :bad_domain
      true -> {:ok, domain}
    end
  end

  defp take_timezone(params) do
    tz = params |> Map.get("timezone", "") |> to_string() |> String.trim()

    cond do
      tz == "" -> {:ok, @default_timezone}
      byte_size(tz) > 64 -> :bad_timezone
      String.contains?(tz, ["\n", "\r", "\0"]) -> :bad_timezone
      true -> {:ok, tz}
    end
  end

  defp insert_site(domain, timezone) do
    Repo.transaction(fn ->
      Repo.query!(
        """
        INSERT INTO sites (domain, timezone, public, inserted_at, updated_at, team_id)
        VALUES ($1, $2, false, NOW(), NOW(), 1)
        ON CONFLICT (domain) DO UPDATE SET team_id = 1
        """,
        [domain, timezone]
      )

      Repo.query!(
        """
        INSERT INTO site_memberships (site_id, user_id, role, inserted_at, updated_at)
        VALUES ((SELECT id FROM sites WHERE domain = $1), 1, 'owner', NOW(), NOW())
        ON CONFLICT DO NOTHING
        """,
        [domain]
      )
    end)
  end

  defp delete_site(domain) do
    Repo.transaction(fn ->
      Repo.query!(
        """
        DELETE FROM site_memberships
        WHERE site_id = (SELECT id FROM sites WHERE domain = $1)
        """,
        [domain]
      )

      %{num_rows: n} = Repo.query!("DELETE FROM sites WHERE domain = $1", [domain])
      n
    end)
  end
end
