# priv/geodata

`city_coords.tsv` — `GeoNames id <TAB> latitude <TAB> longitude` for the cities in the `location`
dictionary that GeoNames lists with more than 15,000 inhabitants (27,839 rows).

Used only by `Plausible.Ingestion.GeoNames` to tell apart cities that share a name inside one
country ("Springfield", "Mountain View"), by nearest distance to the coordinates the IP database
returns. A city without a row here can never be chosen, so a far-away big namesake yields no city
rather than a wrong one.

- Source: GeoNames `cities15000.zip`, <https://download.geonames.org/export/dump/>
- Licence: CC BY 4.0, attribution "GeoNames, https://www.geonames.org"
- Regenerate: keep rows of `cities15000.txt` (columns 1, 5, 6 = id, latitude, longitude) whose id
  appears in `deps/location/priv/geonames.lite.csv`; round to 3 decimals; prefix with the `#` header.
