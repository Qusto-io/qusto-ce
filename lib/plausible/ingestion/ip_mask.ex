defmodule Plausible.Ingestion.IPMask do
  @moduledoc """
  Masks the client IP before it enters the daily visitor hash, for sites that
  need it (G5, CONSENT-MODES P5).

  Italy: the Garante's Guidelines of 10 June 2021 (§7.2) treat analytics as
  exempt from consent only if the provider masks "almeno della quarta
  componente dell'indirizzo" IPv4. The daily `user_id` is
  `SipHash(salt, user_agent <> remote_ip <> domain <> root_domain …)`, so for a
  listed site the IP in that input is reduced to IPv4 /24 or IPv6 /48 first.
  An IPv4-mapped IPv6 address is masked as IPv4 /24.

  Only the hash input changes. Geolocation and Shields IP rules still see the
  request IP, which is never stored.

  ## How a site is listed

  Runtime config, not a database column: `IP_MASK_DOMAINS`, a comma-separated
  list of site domains (case-insensitive). CE production deploys do not run
  Ecto migrations, so a new `sites` column would need a manual migration on
  prod; an env var needs only a restart. The list lives in `lib/`, so it is
  compiled into the `MIX_ENV=ce` build that production runs.

  EE sets `sites.consent_market = 'IT'` from the shop's country; until EE
  writes a CE-side flag, the operator adds each Italian site's domain here.
  """

  import Bitwise

  @spec hash_ip(String.t(), String.t() | nil) :: String.t()
  def hash_ip(remote_ip, domain) do
    if mask?(domain), do: mask(remote_ip), else: remote_ip
  end

  @spec mask?(String.t() | nil) :: boolean()
  def mask?(nil), do: false

  def mask?(domain) when is_binary(domain) do
    case domains() do
      [] -> false
      set -> MapSet.member?(set, String.downcase(domain))
    end
  end

  @spec mask(String.t()) :: String.t()
  def mask(ip) when is_binary(ip) do
    case :inet.parse_strict_address(String.to_charlist(ip)) do
      {:ok, {a, b, c, _d}} ->
        to_string(:inet.ntoa({a, b, c, 0}))

      {:ok, {0, 0, 0, 0, 0, 0xFFFF, hi, lo}} ->
        to_string(:inet.ntoa({hi >>> 8, hi &&& 0xFF, lo >>> 8, 0}))

      {:ok, {a, b, c, _, _, _, _, _}} ->
        to_string(:inet.ntoa({a, b, c, 0, 0, 0, 0, 0}))

      {:error, _} ->
        ip
    end
  end

  def mask(ip), do: ip

  defp domains do
    :plausible
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:domains, [])
  end
end
