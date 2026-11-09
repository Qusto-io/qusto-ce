defmodule Plausible.Ingestion.GeoNames do
  @moduledoc """
  Resolves GeoNames city ids and ISO 3166-2 region codes from the *names* (and
  coordinates) in a geolocation record.

  CE stores `city_geoname_id` and `subdivision1_code` ("US-CA") and reads their
  display names back through the `location` dictionary. MaxMind records carry
  those ids (`city.geoname_id`, `subdivisions[].iso_code`). The DB-IP City Lite
  database we ship carries **names and coordinates only** for city and
  subdivisions, so without this module every visit kept just its country and
  region/city stayed empty (NCOM-01 / LOK-01 finding, 2026-11-02).

  Resolution is conservative: when a name cannot be matched to exactly one place,
  the field stays `nil`. A wrong city in a dashboard is worse than a missing one.

    * **Region** — exact match on the accent- and case-folded name within the
      country, against ISO 3166-2 names (also the part before a comma, so
      "Madrid" finds "Madrid, Comunidad de"). If several regions share the name,
      the highest-level type wins (an autonomous community over a province); a
      remaining tie is `nil`.
    * **City** — exact match on the folded GeoNames name within the country. A
      name shared by several cities is resolved by coordinates: the nearest
      candidate to the record's latitude/longitude, only if it is within
      25 km (candidates have coordinates when the city has more than 15,000
      inhabitants, see `priv/geodata/city_coords.tsv`). No candidate close enough
      means `nil`.

  The index is built once at boot (`build_index/0`) and kept in `:persistent_term`.

  City coordinates: GeoNames (https://www.geonames.org), CC BY 4.0.
  """

  @index_key {__MODULE__, :index}
  @max_km 25.0

  @type index :: %{
          cities: %{{String.t(), String.t()} => pos_integer() | {:ambiguous, [pos_integer()]}},
          regions: %{{String.t(), String.t()} => [{String.t(), non_neg_integer()}]},
          coords: %{pos_integer() => {float(), float()}}
        }

  # Lower = higher-level administrative division. Only used to break a tie between
  # same-named regions in one country; unknown types rank last.
  @type_rank %{
    "Country" => 0,
    "State" => 1,
    "Land" => 1,
    "Regional state" => 1,
    "Autonomous community" => 1,
    "Autonomous region" => 1,
    "Region" => 2,
    "Administrative region" => 2,
    "Metropolitan region" => 2,
    "Republic" => 2,
    "Canton" => 2,
    "Voivodship" => 2,
    "Union territory" => 2,
    "Governorate" => 3,
    "Prefecture" => 3,
    "Province" => 4,
    "Department" => 5,
    "Metropolitan department" => 5,
    "County" => 6
  }
  @default_rank 50

  @doc "Builds the index from the `location` data and stores it. Idempotent."
  @spec build_index() :: :ok
  def build_index do
    index =
      build_index(
        Location.City.all(),
        Location.Subdivision.all(),
        load_coords(),
        load_original_names()
      )

    :persistent_term.put(@index_key, index)
    :ok
  end

  @doc """
  Pure builder. `cities` and `subdivisions` are structs/maps with the fields of
  `Location.City` / `Location.Subdivision`; `coords` maps a GeoNames id to
  `{lat, lon}` for the cities that have coordinates.
  """
  @spec build_index(Enumerable.t(), Enumerable.t(), map(), map()) :: index()
  def build_index(cities, subdivisions, coords \\ %{}, original_names \\ %{}) do
    city_index =
      Enum.reduce(cities, %{}, fn %{id: id, name: name, country_code: cc}, acc ->
        Map.update(acc, {cc, fold(name)}, id, fn
          ^id -> id
          {:ambiguous, ids} -> {:ambiguous, Enum.uniq([id | ids])}
          other -> {:ambiguous, [id, other]}
        end)
      end)

    region_index =
      Enum.reduce(subdivisions, %{}, fn sub, acc ->
        %{code: code, name: name, country_code: cc} = sub
        rank = Map.get(@type_rank, Map.get(sub, :type), @default_rank)

        # `location` serves English translations ("Washington DC", "Gyeonggi"); DB-IP
        # often uses the original ISO spelling ("District of Columbia", "Gyeonggi-do").
        # Index both.
        [name, Map.get(original_names, code)]
        |> Enum.reject(&is_nil/1)
        |> Enum.flat_map(&region_name_variants/1)
        |> Enum.uniq()
        |> Enum.reduce(acc, fn variant, acc2 ->
          Map.update(acc2, {cc, variant}, [{code, rank}], &[{code, rank} | &1])
        end)
      end)

    %{cities: city_index, regions: region_index, coords: coords}
  end

  @doc "ISO 3166-2 code for a region name within a country, or nil when unknown or ambiguous."
  @spec subdivision_code(String.t() | nil, String.t() | nil) :: String.t() | nil
  def subdivision_code(country_code, name), do: subdivision_code(index(), country_code, name)

  @doc false
  def subdivision_code(_index, nil, _name), do: nil
  def subdivision_code(_index, _cc, nil), do: nil

  def subdivision_code(%{regions: regions}, country_code, name) do
    case Map.get(regions, {country_code, fold(name)}) do
      nil ->
        nil

      candidates ->
        best = candidates |> Enum.map(&elem(&1, 1)) |> Enum.min()

        case candidates
             |> Enum.filter(fn {_code, rank} -> rank == best end)
             |> Enum.map(&elem(&1, 0))
             |> Enum.uniq() do
          [code] -> code
          _tie -> nil
        end
    end
  end

  @doc """
  GeoNames id of the city with this name in the country, or nil. A name shared by
  several cities needs `lat`/`lon` to be resolved (nearest within 25 km).
  """
  @spec city_geoname_id(String.t() | nil, String.t() | nil, number() | nil, number() | nil) ::
          pos_integer() | nil
  def city_geoname_id(country_code, name, lat \\ nil, lon \\ nil),
    do: city_geoname_id(index(), country_code, name, lat, lon)

  @doc false
  def city_geoname_id(_index, nil, _name, _lat, _lon), do: nil
  def city_geoname_id(_index, _cc, nil, _lat, _lon), do: nil

  def city_geoname_id(%{cities: cities, coords: coords}, country_code, name, lat, lon) do
    # DB-IP appends a neighbourhood in brackets ("San Jose (Tasman and Zanker)").
    # Try the name as given, then without the bracket.
    [name, strip_brackets(name)]
    |> Enum.uniq()
    |> Enum.map(&alias_for(country_code, &1))
    |> Enum.find_value(fn candidate ->
      case Map.get(cities, {country_code, fold(candidate)}) do
        id when is_integer(id) -> id
        {:ambiguous, ids} when is_number(lat) and is_number(lon) -> nearest(ids, coords, lat, lon)
        _unknown_or_ambiguous_without_location -> nil
      end
    end)
  end

  # DB-IP spellings that differ from GeoNames for high-traffic places (found by sampling
  # the database against the dictionary, 2026-11-02). Keep this list short and evidence-led.
  @city_aliases %{
    {"US", "new york"} => "New York City",
    {"US", "washington d c"} => "Washington",
    {"US", "indpls"} => "Indianapolis"
  }
  defp alias_for(country_code, name),
    do: Map.get(@city_aliases, {country_code, fold(name)}, name)

  defp strip_brackets(name), do: name |> String.replace(~r/\s*\([^)]*\)/u, "") |> String.trim()

  # Nearest candidate that has coordinates, if within @max_km. A candidate without
  # coordinates (a small town) can never win, so a far-away big namesake yields nil.
  defp nearest(ids, coords, lat, lon) do
    ids
    |> Enum.flat_map(fn id ->
      case Map.get(coords, id) do
        {clat, clon} -> [{distance_km(lat, lon, clat, clon), id}]
        nil -> []
      end
    end)
    |> Enum.min(fn -> nil end)
    |> case do
      {km, id} when km <= @max_km -> id
      _none_close_enough -> nil
    end
  end

  # Great-circle distance (haversine), kilometres.
  defp distance_km(lat1, lon1, lat2, lon2) do
    rad = :math.pi() / 180
    dlat = (lat2 - lat1) * rad
    dlon = (lon2 - lon1) * rad

    a =
      :math.pow(:math.sin(dlat / 2), 2) +
        :math.cos(lat1 * rad) * :math.cos(lat2 * rad) * :math.pow(:math.sin(dlon / 2), 2)

    6371.0 * 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))
  end

  @doc """
  Folds a place name for matching: accents removed, case-insensitive,
  punctuation collapsed. "Baden-Württemberg" and "Baden-Wurttemberg" fold equal.
  """
  @spec fold(String.t()) :: String.t()
  def fold(name) when is_binary(name) do
    name
    |> String.downcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/\p{Mn}/u, "")
    |> replace_special_letters()
    |> String.replace(~r/[^\p{L}\p{N}]+/u, " ")
    |> String.trim()
  end

  # Letters that do not decompose into base + combining mark.
  @special %{
    "ß" => "ss",
    "æ" => "ae",
    "œ" => "oe",
    "ø" => "o",
    "ð" => "d",
    "þ" => "th",
    "đ" => "d",
    "ł" => "l",
    "ı" => "i"
  }
  defp replace_special_letters(string) do
    Enum.reduce(@special, string, fn {from, to}, acc -> String.replace(acc, from, to) end)
  end

  # ISO names carry administrative words DB-IP leaves out: "Madrid Autonomous
  # Community" and "Madrid Province" are both reachable as "Madrid"; "Madrid, Comunidad
  # de" likewise; "Foo (Bar)" as "Foo". (Same-name regions are then ranked by type.)
  @generic_suffixes [
    "autonomous community",
    "autonomous region",
    "province",
    "region",
    "state",
    "county",
    "department",
    "district",
    "governorate",
    "prefecture",
    "municipality",
    "canton"
  ]

  defp region_name_variants(name) do
    before_comma = name |> String.split(",", parts: 2) |> hd()
    without_parens = String.replace(name, ~r/\s*\([^)]*\)/u, "")

    folded =
      [name, before_comma, without_parens]
      |> Enum.map(&fold/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()

    stripped =
      for variant <- folded,
          suffix <- @generic_suffixes,
          String.ends_with?(variant, " " <> suffix),
          shorter = String.replace_suffix(variant, " " <> suffix, ""),
          shorter != "",
          do: shorter

    Enum.uniq(folded ++ stripped)
  end

  defp load_coords do
    path =
      Application.get_env(:plausible, __MODULE__, [])[:coords_path] ||
        Path.join(:code.priv_dir(:plausible), "geodata/city_coords.tsv")

    case File.read(path) do
      {:ok, body} ->
        for line <- String.split(body, "\n", trim: true),
            not String.starts_with?(line, "#"),
            [id, lat, lon] <- [String.split(line, "\t")],
            into: %{} do
          {String.to_integer(id), {String.to_float(lat), String.to_float(lon)}}
        end

      {:error, _} ->
        %{}
    end
  end

  # Original (untranslated) ISO 3166-2 names, by code.
  defp load_original_names do
    with {:ok, body} <- File.read(Application.app_dir(:location, "priv/iso_3166-2.json")),
         {:ok, %{"3166-2" => entries}} <- Jason.decode(body) do
      Map.new(entries, &{&1["code"], &1["name"]})
    else
      _ -> %{}
    end
  end

  defp index do
    case :persistent_term.get(@index_key, nil) do
      nil ->
        build_index()
        :persistent_term.get(@index_key)

      index ->
        index
    end
  end
end
