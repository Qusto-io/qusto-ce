defmodule Plausible.Qusto.AiReferrer do
  @moduledoc """
  Schema for AI search engine reference data.

  Maintains a mapping of known AI search engines and assistants,
  their referral patterns, and display metadata for the dashboard.

  Categories:
  - ai_search: General AI search engines (Perplexity, ChatGPT web, Gemini)
  - ai_assistant: AI assistants that can browse/cite sources (Claude, Copilot)
  - ai_coding: AI coding assistants (Phind, GitHub Copilot)
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @type t() :: %__MODULE__{}

  @categories ["ai_search", "ai_assistant", "ai_coding"]

  schema "qusto_ai_referrers" do
    field :name, :string
    field :display_name, :string
    field :referrer_patterns, {:array, :string}
    field :utm_patterns, {:array, :string}
    field :category, :string, default: "ai_search"
    field :is_tracked, :boolean, default: true
    field :color_hex, :string
    field :icon_url, :string

    timestamps()
  end

  def categories, do: @categories

  def changeset(referrer \\ %__MODULE__{}, attrs) do
    referrer
    |> cast(attrs, [
      :name,
      :display_name,
      :referrer_patterns,
      :utm_patterns,
      :category,
      :is_tracked,
      :color_hex,
      :icon_url
    ])
    |> validate_required([:name, :display_name, :referrer_patterns])
    |> validate_inclusion(:category, @categories)
    |> validate_length(:referrer_patterns, min: 1)
    |> validate_color_hex()
    |> unique_constraint(:name)
  end

  defp validate_color_hex(changeset) do
    case get_change(changeset, :color_hex) do
      nil ->
        changeset

      color when is_binary(color) ->
        if String.match?(color, ~r/^#[0-9A-Fa-f]{6}$/) do
          changeset
        else
          add_error(changeset, :color_hex, "must be a valid hex color (e.g., #FF5733)")
        end

      _ ->
        changeset
    end
  end

  @doc """
  Returns a query for all tracked AI referrers.
  """
  def tracked_query do
    from(r in __MODULE__, where: r.is_tracked == true, order_by: r.name)
  end

  @doc """
  Matches a referrer URL against known AI referrer patterns.
  Returns the AI referrer name if matched, nil otherwise.
  """
  def match_referrer(referrer_url, referrers) when is_binary(referrer_url) do
    Enum.find_value(referrers, fn ai_ref ->
      if Enum.any?(ai_ref.referrer_patterns, &String.contains?(referrer_url, &1)) do
        ai_ref.name
      end
    end)
  end

  def match_referrer(_, _), do: nil

  @doc """
  Matches a UTM source against known AI UTM patterns.
  Returns the AI referrer name if matched, nil otherwise.
  """
  def match_utm_source(utm_source, referrers) when is_binary(utm_source) do
    utm_lower = String.downcase(utm_source)

    Enum.find_value(referrers, fn ai_ref ->
      patterns = ai_ref.utm_patterns || []
      matches_pattern? = Enum.any?(patterns, &String.contains?(utm_lower, String.downcase(&1)))

      matches_pattern? && ai_ref.name
    end)
  end

  def match_utm_source(_, _), do: nil
end
