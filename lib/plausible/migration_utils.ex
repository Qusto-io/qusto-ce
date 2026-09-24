defmodule Plausible.MigrationUtils do
  @moduledoc """
  Base module for to use in Clickhouse migrations
  """

  use Plausible

  alias Plausible.IngestRepo

  def on_cluster_statement(table) do
    if(IngestRepo.clustered_table?(table), do: "ON CLUSTER '{cluster}'", else: "")
  end

  # See https://clickhouse.com/docs/en/sql-reference/dictionaries#clickhouse for context
  def dictionary_connection_params() do
    IngestRepo.config()
    |> Enum.map(fn
      {:database, database} -> "DB '#{database}'"
      {:username, username} -> "USER '#{username}'"
      {:password, password} -> "PASSWORD '#{password}'"
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  def table_settings() do
    IngestRepo.config()
    |> Keyword.get(:table_settings)
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
  end

  def table_settings_expr(type \\ :prefix) do
    expr = Enum.map_join(table_settings(), ", ", fn {k, v} -> "#{k} = #{encode(v)}" end)

    case {table_settings(), type} do
      {[], _} -> ""
      {_, :prefix} -> "SETTINGS #{expr}"
      {_, :suffix} -> ", #{expr}"
    end
  end

  def enterprise_edition?(), do: ee?()

  def community_edition?(), do: ce?()

  # Table-level MODIFY SETTING lightweight_mutation_projection_mode exists from CH 25.1+.
  # Older clusters (e.g. prod 24.3) skip; workers use query-level SETTINGS instead.
  def clickhouse_version_at_least?({major, minor, patch}) do
    case fetch_clickhouse_version_triple() do
      {:ok, triple} -> version_triple_gte?(triple, {major, minor, patch})
      :error -> false
    end
  end

  defp fetch_clickhouse_version_triple() do
    case Ecto.Adapters.SQL.query(IngestRepo, "SELECT version()", []) do
      {:ok, %{rows: [[version_string]]}} -> parse_clickhouse_version_triple(version_string)
      _ -> :error
    end
  end

  defp parse_clickhouse_version_triple(version_string) do
    case String.split(version_string, ".", parts: 4) do
      [a, b, c, _] ->
        with {maj, _} <- Integer.parse(a),
             {min, _} <- Integer.parse(b),
             {pat, _} <- Integer.parse(c) do
          {:ok, {maj, min, pat}}
        else
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp version_triple_gte?({a, b, c}, {ma, mb, mc}) do
    a > ma or (a == ma and (b > mb or (b == mb and c >= mc)))
  end

  defp encode(value) when is_number(value), do: value
  defp encode(value) when is_binary(value), do: "'#{value}'"
end
