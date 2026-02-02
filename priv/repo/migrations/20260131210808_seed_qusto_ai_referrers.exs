defmodule Plausible.Repo.Migrations.SeedQustoAiReferrers do
  use Ecto.Migration

  def up do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    ai_referrers = [
      %{
        name: "ChatGPT",
        display_name: "ChatGPT",
        referrer_patterns: ["chat.openai.com", "chatgpt.com"],
        utm_patterns: ["chatgpt", "openai"],
        category: "ai_search",
        color_hex: "#74AA9C"
      },
      %{
        name: "Claude",
        display_name: "Claude",
        referrer_patterns: ["claude.ai", "anthropic.com"],
        utm_patterns: ["claude", "anthropic"],
        category: "ai_assistant",
        color_hex: "#D4A574"
      },
      %{
        name: "Perplexity",
        display_name: "Perplexity",
        referrer_patterns: ["perplexity.ai"],
        utm_patterns: ["perplexity"],
        category: "ai_search",
        color_hex: "#20808D"
      },
      %{
        name: "Gemini",
        display_name: "Gemini",
        referrer_patterns: ["gemini.google.com", "bard.google.com"],
        utm_patterns: ["gemini", "bard"],
        category: "ai_search",
        color_hex: "#8E75B2"
      },
      %{
        name: "Copilot",
        display_name: "Microsoft Copilot",
        referrer_patterns: ["copilot.microsoft.com", "bing.com/chat"],
        utm_patterns: ["copilot"],
        category: "ai_assistant",
        color_hex: "#00A4EF"
      },
      %{
        name: "You",
        display_name: "You.com",
        referrer_patterns: ["you.com"],
        utm_patterns: ["you.com"],
        category: "ai_search",
        color_hex: "#5436DA"
      },
      %{
        name: "Phind",
        display_name: "Phind",
        referrer_patterns: ["phind.com"],
        utm_patterns: ["phind"],
        category: "ai_coding",
        color_hex: "#6366F1"
      },
      %{
        name: "Kagi",
        display_name: "Kagi",
        referrer_patterns: ["kagi.com"],
        utm_patterns: ["kagi"],
        category: "ai_search",
        color_hex: "#FFB319"
      },
      %{
        name: "DeepSeek",
        display_name: "DeepSeek",
        referrer_patterns: ["deepseek.com", "chat.deepseek.com"],
        utm_patterns: ["deepseek"],
        category: "ai_search",
        color_hex: "#4F46E5"
      },
      %{
        name: "Poe",
        display_name: "Poe",
        referrer_patterns: ["poe.com"],
        utm_patterns: ["poe"],
        category: "ai_assistant",
        color_hex: "#5C6BC0"
      }
    ]

    for referrer <- ai_referrers do
      execute """
      INSERT INTO qusto_ai_referrers (name, display_name, referrer_patterns, utm_patterns, category, color_hex, is_tracked, inserted_at, updated_at)
      VALUES (
        '#{referrer.name}',
        '#{referrer.display_name}',
        ARRAY[#{Enum.map_join(referrer.referrer_patterns, ", ", &"'#{&1}'")}]::text[],
        ARRAY[#{Enum.map_join(referrer.utm_patterns, ", ", &"'#{&1}'")}]::text[],
        '#{referrer.category}',
        '#{referrer.color_hex}',
        true,
        '#{now}',
        '#{now}'
      )
      ON CONFLICT (name) DO NOTHING
      """
    end
  end

  def down do
    execute """
    DELETE FROM qusto_ai_referrers
    WHERE name IN ('ChatGPT', 'Claude', 'Perplexity', 'Gemini', 'Copilot', 'You', 'Phind', 'Kagi', 'DeepSeek', 'Poe')
    """
  end
end
