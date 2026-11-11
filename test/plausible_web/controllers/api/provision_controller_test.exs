defmodule PlausibleWeb.Api.ProvisionControllerTest do
  use PlausibleWeb.ConnCase, async: false

  @token "test-provision-secret"

  setup do
    previous = Application.get_env(:plausible, :provision_token)
    Application.put_env(:plausible, :provision_token, @token)

    on_exit(fn ->
      if previous do
        Application.put_env(:plausible, :provision_token, previous)
      else
        Application.delete_env(:plausible, :provision_token)
      end
    end)

    Plausible.Repo.query!("""
    INSERT INTO users (id, email, password_hash, name, email_verified, inserted_at, updated_at)
    VALUES (1, 'provision@qusto.test', 'not-used', 'Provision', true, NOW(), NOW())
    ON CONFLICT (id) DO NOTHING
    """)

    Plausible.Repo.query!("""
    INSERT INTO teams (
      id, identifier, name, trial_expiry_date, accept_traffic_until,
      allow_next_upgrade_override, inserted_at, updated_at
    )
    VALUES (
      1, '00000000-0000-4000-8000-000000000001', 'Provision Team',
      CURRENT_DATE + 30, CURRENT_DATE + 44, false, NOW(), NOW()
    )
    ON CONFLICT (id) DO NOTHING
    """)

    :ok
  end

  test "creates a site row, repeats cleanly, then deletes it", %{conn: conn} do
    domain = "provision-#{System.unique_integer([:positive])}.example"
    before = counts()

    conn =
      conn
      |> auth()
      |> post("/api/v1/sites", %{"domain" => domain, "timezone" => ""})

    assert json_response(conn, 200)["domain"] == domain
    assert site_row(domain) == {"Europe/Berlin", 1, false}
    assert membership_count(domain) == 1

    after_create = counts()
    assert after_create.sites == before.sites + 1
    assert after_create.memberships == before.memberships + 1
    assert after_create.users == before.users
    assert after_create.teams == before.teams
    assert after_create.goals == before.goals

    conn =
      build_conn()
      |> auth()
      |> post("/api/v1/sites", %{"domain" => domain, "timezone" => "Europe/Madrid"})

    assert json_response(conn, 200)["domain"] == domain
    assert counts().sites == after_create.sites
    # Repeat keeps the first timezone. The conflict update only sets team_id.
    assert site_row(domain) == {"Europe/Berlin", 1, false}

    conn = build_conn() |> auth() |> delete("/api/v1/sites/#{domain}")
    assert response(conn, 200) == ""
    assert site_row(domain) == nil
    assert membership_count(domain) == 0

    conn = build_conn() |> auth() |> delete("/api/v1/sites/#{domain}")
    assert response(conn, 404) == ""
  end

  test "stores a provided timezone", %{conn: conn} do
    domain = "tz-#{System.unique_integer([:positive])}.example"

    conn =
      conn
      |> auth()
      |> post("/api/v1/sites", %{"domain" => domain, "timezone" => "Europe/Madrid"})

    assert json_response(conn, 200)["domain"] == domain
    assert site_row(domain) == {"Europe/Madrid", 1, false}
  end

  test "a missing token writes nothing", %{conn: conn} do
    Application.delete_env(:plausible, :provision_token)
    domain = "disabled-#{System.unique_integer([:positive])}.example"
    before = counts()

    conn = post(conn, "/api/v1/sites", %{"domain" => domain})
    assert response(conn, 404) == ""
    assert counts() == before
    assert site_row(domain) == nil
  end

  test "a wrong token writes nothing", %{conn: conn} do
    domain = "denied-#{System.unique_integer([:positive])}.example"
    before = counts()

    conn =
      conn
      |> put_req_header("authorization", "Bearer not-the-token")
      |> post("/api/v1/sites", %{"domain" => domain})

    assert response(conn, 401) == ""
    assert counts() == before
  end

  test "an empty domain is rejected", %{conn: conn} do
    before = counts()
    conn = conn |> auth() |> post("/api/v1/sites", %{"domain" => "  "})
    assert response(conn, 400) == ""
    assert counts() == before
  end

  defp auth(conn), do: put_req_header(conn, "authorization", "Bearer #{@token}")

  defp counts do
    %{
      sites: count("sites"),
      memberships: count("site_memberships"),
      users: count("users"),
      teams: count("teams"),
      goals: count("goals")
    }
  end

  defp count(table) do
    %{rows: [[n]]} = Plausible.Repo.query!("SELECT COUNT(*) FROM " <> table)
    n
  end

  defp site_row(domain) do
    case Plausible.Repo.query!(
           "SELECT timezone, team_id, public FROM sites WHERE domain = $1",
           [domain]
         ) do
      %{rows: [[timezone, team_id, public]]} -> {timezone, team_id, public}
      %{rows: []} -> nil
    end
  end

  defp membership_count(domain) do
    %{rows: [[n]]} =
      Plausible.Repo.query!(
        """
        SELECT COUNT(*) FROM site_memberships
        WHERE site_id = (SELECT id FROM sites WHERE domain = $1)
        """,
        [domain]
      )

    n
  end
end
