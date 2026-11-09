defmodule Plausible.Ingestion.GeolocationTest do
  use ExUnit.Case, async: true

  alias Plausible.Ingestion.Geolocation

  # What a MaxMind GeoLite2 City record carries: ids and ISO codes. Must keep working unchanged.
  test "from_entry/1 keeps the ids and ISO codes a MaxMind record carries" do
    entry = %{
      "country" => %{"iso_code" => "US", "geoname_id" => 6_252_001},
      "city" => %{"geoname_id" => 5_349_755, "names" => %{"en" => "Fontana"}},
      "subdivisions" => [%{"iso_code" => "CA", "names" => %{"en" => "California"}}]
    }

    assert Geolocation.from_entry(entry) == %{
             country_code: "US",
             subdivision1_code: "US-CA",
             subdivision2_code: nil,
             city_geoname_id: 5_349_755
           }
  end

  test "from_entry/1 reads a second MaxMind subdivision" do
    entry = %{
      "country" => %{"iso_code" => "GB"},
      "subdivisions" => [%{"iso_code" => "ENG"}, %{"iso_code" => "LND"}]
    }

    assert %{subdivision1_code: "GB-ENG", subdivision2_code: "GB-LND"} =
             Geolocation.from_entry(entry)
  end

  # What a DB-IP City Lite record carries: names and coordinates, no ids (production, 2026-11-02).
  test "from_entry/1 resolves a DB-IP record from its names" do
    entry = %{
      "country" => %{"iso_code" => "GB", "geoname_id" => 2_635_167},
      "city" => %{"names" => %{"en" => "London"}},
      "subdivisions" => [%{"names" => %{"en" => "England"}}],
      "location" => %{"latitude" => 51.5143, "longitude" => -0.0912244}
    }

    assert Geolocation.from_entry(entry) == %{
             country_code: "GB",
             subdivision1_code: "GB-ENG",
             subdivision2_code: nil,
             city_geoname_id: 2_643_743
           }
  end

  test "from_entry/1 uses the record's coordinates to tell same-named cities apart" do
    entry = %{
      "country" => %{"iso_code" => "US"},
      "city" => %{"names" => %{"en" => "Mountain View"}},
      "subdivisions" => [%{"names" => %{"en" => "California"}}],
      "location" => %{"latitude" => 37.422, "longitude" => -122.085}
    }

    assert %{city_geoname_id: 5_375_480, subdivision1_code: "US-CA"} =
             Geolocation.from_entry(entry)
  end

  test "from_entry/1 keeps the country when the names cannot be resolved" do
    entry = %{
      "country" => %{"iso_code" => "ES"},
      "city" => %{"names" => %{"en" => "Nowhereville"}},
      "subdivisions" => [%{"names" => %{"en" => "Nowhere"}}],
      "location" => %{"latitude" => 40.0, "longitude" => -3.0}
    }

    assert Geolocation.from_entry(entry) == %{
             country_code: "ES",
             subdivision1_code: nil,
             subdivision2_code: nil,
             city_geoname_id: nil
           }
  end

  test "from_entry/1 ignores unknown countries and resolves nothing for them" do
    entry = %{
      "country" => %{"iso_code" => "ZZ"},
      "city" => %{"names" => %{"en" => "London"}},
      "subdivisions" => [%{"names" => %{"en" => "England"}}]
    }

    assert Geolocation.from_entry(entry) == %{
             country_code: nil,
             subdivision1_code: nil,
             subdivision2_code: nil,
             city_geoname_id: nil
           }
  end

  test "from_entry/1 copes with a record that has no city or subdivisions" do
    assert Geolocation.from_entry(%{"country" => %{"iso_code" => "DE"}}) == %{
             country_code: "DE",
             subdivision1_code: nil,
             subdivision2_code: nil,
             city_geoname_id: nil
           }
  end
end
