defmodule Plausible.Ingestion.UtmSessionLandingTest do
  @moduledoc """
  G4 (2026-10-13): pins how UTMs reach `events_v2`, replaying the exact
  `/api/event` bodies captured in the A1(i) live test
  (vault evidence `A1_PIXEL_CONSENT_20261013/R1_qusto_requests.json`).

  UTMs are *session* attributes: `Plausible.Ingestion.Persistor.Embedded`
  merges the session into every event (`ClickhouseEventV2.merge_session/2`),
  and an existing session keeps the UTMs of the hit that opened it
  (`Plausible.Session.CacheStore.update_session/2` never touches utm_*).
  So a UTM-tagged pageview that lands inside a session opened by an untagged
  hit is stored with empty UTMs. That is what happened in A1: each run first
  loaded `/` (no query), then the UTM URL ~3 s later from the same browser.
  """
  use PlausibleWeb.ConnCase
  use Plausible.ClickhouseRepo

  @ua "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36"
  @utm_url "https://qusto-demo.myshopify.com/?utm_source=TEST-a1&utm_medium=test&utm_campaign=TEST-A1-R1-20261013-1515"

  setup do
    {:ok, site: new_site(domain: "qusto-demo.myshopify.com")}
  end

  defp send_tracker_body(name, url) do
    # Byte-for-byte shape of the CE tracker (v36) body captured live.
    body = Jason.encode!(%{n: name, v: 36, u: url, d: "qusto-demo.myshopify.com", r: nil})

    conn =
      build_conn()
      |> put_req_header("user-agent", @ua)
      |> put_req_header("content-type", "text/plain")
      |> post("/api/event", body)

    assert response(conn, 202) == "ok"
  end

  defp events(site) do
    Plausible.Event.WriteBuffer.flush()

    ClickhouseRepo.all(
      from(e in Plausible.ClickhouseEventV2,
        where: e.site_id == ^site.id,
        select: %{name: e.name, utm_source: e.utm_source, utm_campaign: e.utm_campaign},
        order_by: [asc: e.timestamp]
      )
    )
  end

  test "UTM URL as the landing hit: utm_* persisted on every event in events_v2", %{site: site} do
    send_tracker_body("pageview", @utm_url)

    send_tracker_body(
      "pageview",
      "https://qusto-demo.myshopify.com/products/voltera-cable-2m-usb-c"
    )

    evs = events(site)
    assert length(evs) == 2
    assert Enum.all?(evs, &(&1.utm_source == "TEST-a1"))
    assert Enum.all?(evs, &(&1.utm_campaign == "TEST-A1-R1-20261013-1515"))
  end

  test "A1 sequence (untagged `/` first, UTM URL second): session keeps landing UTMs (empty)",
       %{site: site} do
    send_tracker_body("pageview", "https://qusto-demo.myshopify.com/")
    send_tracker_body("pageview", @utm_url)

    evs = events(site)
    assert length(evs) == 2
    # The tagged hit is ingested, but inherits the untagged session's UTMs.
    assert Enum.all?(evs, &(&1.utm_campaign == ""))
    assert Enum.all?(evs, &(&1.utm_source == ""))
  end
end
