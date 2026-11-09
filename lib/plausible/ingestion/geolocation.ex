defmodule Plausible.Ingestion.Geolocation do
  @moduledoc false

  def lookup(ip_address) do
    case Plausible.Geo.lookup(ip_address) do
      %{} = entry -> from_entry(entry)
      nil -> nil
    end
  end

  @doc false
  # The record -> stored fields step, separate from the IP lookup so both database
  # formats (MaxMind ids, DB-IP names) can be tested without a database file.
  def from_entry(%{} = entry) do
    country_code =
      entry
      |> get_in(["country", "iso_code"])
      |> ignore_unknown_country()

    city_geoname_id = country_code && city_geoname_id(country_code, entry)
    city_geoname_id = Plausible.Ingestion.CityOverrides.get(city_geoname_id, city_geoname_id)

    %{
      country_code: country_code,
      subdivision1_code: subdivision_code(country_code, entry, 0),
      subdivision2_code: subdivision_code(country_code, entry, 1),
      city_geoname_id: city_geoname_id
    }
  end

  # MaxMind records carry the id. DB-IP City Lite carries the name only, so fall
  # back to resolving it (GeoNames); an ambiguous name stays nil.
  defp city_geoname_id(country_code, entry) do
    case get_in(entry, ["city", "geoname_id"]) do
      nil ->
        Plausible.Ingestion.GeoNames.city_geoname_id(
          country_code,
          english_name(entry["city"]),
          get_in(entry, ["location", "latitude"]),
          get_in(entry, ["location", "longitude"])
        )

      id ->
        id
    end
  end

  # An ISO code in the record wins (MaxMind). Otherwise resolve the first
  # subdivision's name to an ISO 3166-2 code (DB-IP). DB-IP has a single level,
  # so the second subdivision is only ever taken from an explicit ISO code.
  defp subdivision_code(country_code, entry, position) when not is_nil(country_code) do
    case entry |> Map.get("subdivisions", []) |> Enum.at(position) do
      %{"iso_code" => iso_code} ->
        country_code <> "-" <> iso_code

      %{} = subdivision when position == 0 ->
        Plausible.Ingestion.GeoNames.subdivision_code(country_code, english_name(subdivision))

      _ ->
        nil
    end
  end

  defp subdivision_code(_country_code, _entry, _position), do: nil

  defp english_name(%{"names" => %{"en" => name}}) when is_binary(name), do: name
  defp english_name(_), do: nil

  @ignored_countries [
    # Worldwide
    "ZZ",
    # Disputed territory
    "XX",
    # Tor exit node
    "T1"
  ]
  defp ignore_unknown_country(code) when code in @ignored_countries, do: nil
  defp ignore_unknown_country(country), do: country
end
