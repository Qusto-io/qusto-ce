defmodule Plausible.Ingestion.ConsentGate do
  @moduledoc """
  Drops events that arrive without analytics consent (CPOL-01 C1).

  `qusto.js` already sends nothing before consent; this is the server-side
  check, for anything that reaches the event endpoint another way. The tracker
  marks each event with the `consent` prop ("true" or "false").

  ## Configuration

  Runtime config, like `Plausible.Ingestion.IPMask`: CE production deploys do not
  run Ecto migrations, and an env var needs only a restart.

    * `CONSENT_REQUIRED`: "true" turns the gate on. Off by default, so a
      self-hosted CE behaves as upstream does.
    * `CONSENT_AGGREGATE_DOMAINS`: comma-separated sites allowed to keep their
      no-consent pageview, the `data-consent="aggregate"` mode.
  """

  @spec allow?(String.t() | nil, map() | nil) :: boolean()
  def allow?(domain, props) do
    not required?() or consented?(props) or aggregate?(domain)
  end

  defp consented?(%{"consent" => "true"}), do: true
  defp consented?(_props), do: false

  defp aggregate?(nil), do: false

  defp aggregate?(domain) when is_binary(domain) do
    case Keyword.get(config(), :aggregate_domains, []) do
      [] -> false
      set -> MapSet.member?(set, String.downcase(domain))
    end
  end

  defp required?, do: Keyword.get(config(), :required, false)

  defp config, do: Application.get_env(:plausible, __MODULE__, [])
end
