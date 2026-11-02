defmodule Plausible.Ingestion.GeoNamesTest do
  use ExUnit.Case, async: true

  alias Plausible.Ingestion.GeoNames

  describe "fold/1" do
    test "removes accents, case and punctuation" do
      assert GeoNames.fold("Baden-Württemberg") == GeoNames.fold("Baden-Wurttemberg")
      assert GeoNames.fold("Zürich") == "zurich"
      assert GeoNames.fold("Łódź") == "lodz"
      assert GeoNames.fold("Straße") == "strasse"
      assert GeoNames.fold("  St. John's  ") == "st john s"
    end
  end

  describe "build_index/4 (fixtures)" do
    @cities [
      %{id: 1, name: "Springfield", country_code: "US"},
      %{id: 2, name: "Springfield", country_code: "US"},
      %{id: 3, name: "Springfield", country_code: "US"},
      %{id: 10, name: "Madrid", country_code: "ES"},
      %{id: 20, name: "Zürich", country_code: "CH"}
    ]
    @subdivisions [
      %{code: "ES-M", name: "Madrid Province", type: "Province", country_code: "ES"},
      %{
        code: "ES-MD",
        name: "Madrid Autonomous Community",
        type: "Autonomous community",
        country_code: "ES"
      },
      %{code: "XX-A", name: "Twin", type: "Province", country_code: "XX"},
      %{code: "XX-B", name: "Twin", type: "Province", country_code: "XX"},
      %{code: "US-DC", name: "Washington DC", type: "District", country_code: "US"}
    ]
    # Springfield #1 is in Illinois, #2 in Massachusetts; #3 is a small town with no coordinates.
    @coords %{1 => {39.80, -89.64}, 2 => {42.10, -72.59}}

    setup do
      {:ok,
       index:
         GeoNames.build_index(@cities, @subdivisions, @coords, %{
           "US-DC" => "District of Columbia"
         })}
    end

    test "a name unique in the country resolves, accents ignored", %{index: i} do
      assert GeoNames.city_geoname_id(i, "ES", "Madrid", nil, nil) == 10
      assert GeoNames.city_geoname_id(i, "CH", "Zurich", nil, nil) == 20
    end

    test "an ambiguous name is not guessed without a location", %{index: i} do
      assert GeoNames.city_geoname_id(i, "US", "Springfield", nil, nil) == nil
    end

    test "an ambiguous name resolves to the nearest candidate within 25 km", %{index: i} do
      assert GeoNames.city_geoname_id(i, "US", "Springfield", 39.78, -89.65) == 1
      assert GeoNames.city_geoname_id(i, "US", "Springfield", 42.11, -72.55) == 2
    end

    test "an ambiguous name far from every candidate stays nil (never a wrong city)", %{index: i} do
      # Near the small town #3, which has no coordinates, and far from #1 and #2.
      assert GeoNames.city_geoname_id(i, "US", "Springfield", 44.05, -123.02) == nil
    end

    test "unknown cities and missing inputs are nil", %{index: i} do
      assert GeoNames.city_geoname_id(i, "ES", "Atlantis", nil, nil) == nil
      assert GeoNames.city_geoname_id(i, nil, "Madrid", nil, nil) == nil
      assert GeoNames.city_geoname_id(i, "ES", nil, nil, nil) == nil
    end

    test "a bracketed neighbourhood is dropped when the full name has no match", %{index: i} do
      assert GeoNames.city_geoname_id(i, "ES", "Madrid (Chamberí)", nil, nil) == 10
    end

    test "a region name matches the ISO name with or without its administrative word", %{index: i} do
      assert GeoNames.subdivision_code(i, "US", "Washington DC") == "US-DC"
      assert GeoNames.subdivision_code(i, "US", "District of Columbia") == "US-DC"
    end

    test "same-named regions: the higher-level type wins", %{index: i} do
      assert GeoNames.subdivision_code(i, "ES", "Madrid") == "ES-MD"
    end

    test "same-named regions of equal level are not guessed", %{index: i} do
      assert GeoNames.subdivision_code(i, "XX", "Twin") == nil
    end

    test "regions are scoped to their country", %{index: i} do
      assert GeoNames.subdivision_code(i, "FR", "Madrid") == nil
      assert GeoNames.subdivision_code(i, nil, "Madrid") == nil
    end

    test "known DB-IP spellings map to the GeoNames city", %{index: _} do
      i =
        GeoNames.build_index(
          [%{id: 5_128_581, name: "New York City", country_code: "US"}],
          [],
          %{},
          %{}
        )

      assert GeoNames.city_geoname_id(i, "US", "New York", nil, nil) == 5_128_581
    end
  end

  describe "against the shipped location data" do
    test "cities" do
      assert GeoNames.city_geoname_id("GB", "London") == 2_643_743
      assert GeoNames.city_geoname_id("ES", "Madrid") == 3_117_735
      assert GeoNames.city_geoname_id("DE", "Berlin") == 2_950_159
      assert GeoNames.city_geoname_id("FR", "Paris") == 2_988_507
    end

    test "an ambiguous US name needs coordinates (Mountain View, CA)" do
      assert GeoNames.city_geoname_id("US", "Mountain View") == nil
      assert GeoNames.city_geoname_id("US", "Mountain View", 37.386, -122.0838) == 5_375_480
    end

    test "regions" do
      assert GeoNames.subdivision_code("GB", "England") == "GB-ENG"
      assert GeoNames.subdivision_code("US", "California") == "US-CA"
      assert GeoNames.subdivision_code("DE", "Baden-Wurttemberg") == "DE-BW"
      assert GeoNames.subdivision_code("US", "District of Columbia") == "US-DC"
      assert GeoNames.subdivision_code("ES", "Madrid") == "ES-MD"
    end
  end
end
