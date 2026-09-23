defmodule PlausibleWeb.Components.Settings do
  @moduledoc """
  Shared layout components for settings pages.
  """
  use Phoenix.Component, global_prefixes: ~w(x-)

  import PlausibleWeb.Components.Generic

  alias PlausibleWeb.Live.Components.Form

  slot :inner_block, required: true

  def settings_rows(assigns) do
    ~H"""
    <div class="flex flex-col gap-6">
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:label, :string, default: nil)
  attr(:for, :string, default: nil)
  attr(:docs, :string, default: nil)
  attr(:tooltip, :string, default: nil)
  attr(:actions_class, :any, default: "gap-2.5")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def settings_row(assigns) do
    ~H"""
    <div
      class="flex flex-col items-stretch gap-3 sm:flex-row sm:items-center sm:gap-4 text-sm"
      {@rest}
    >
      <.settings_label
        :if={@label}
        label={@label}
        for={@for}
        docs={@docs}
        tooltip={@tooltip}
      />
      <div class={["flex items-center sm:ml-auto", @actions_class]}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:docs, :string, default: nil)
  attr(:tooltip, :string, default: nil)
  attr(:expandable?, :boolean, default: false)
  slot(:inner_block, required: true)

  def settings_section(%{expandable?: true} = assigns) do
    ~H"""
    <section class="flex flex-col gap-6" x-data="{ open: false }">
      <button
        type="button"
        class="flex items-center justify-between gap-4"
        aria-expanded="false"
        x-bind:aria-expanded="open"
        x-on:click="open = !open"
      >
        <.settings_label label={@title} docs={@docs} tooltip={@tooltip} />
        <Heroicons.chevron_down
          mini
          class="size-4.5 text-gray-500 dark:text-gray-400 transition-transform"
          x-bind:class="open ? 'rotate-180' : ''"
        />
      </button>
      <div x-show="open" x-cloak class="flex flex-col gap-4">
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  def settings_section(assigns) do
    ~H"""
    <section class="flex flex-col gap-6">
      <.settings_label label={@title} docs={@docs} tooltip={@tooltip} />
      <div class="flex flex-col gap-4">
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  attr(:label, :string, required: true)
  attr(:for, :string, default: nil)
  attr(:docs, :string, default: nil)
  attr(:tooltip, :string, default: nil)

  def settings_label(assigns) do
    ~H"""
    <div class="flex items-center gap-1.5">
      <Form.label :if={@for} for={@for}>{@label}</Form.label>
      <span :if={!@for} class="text-sm font-medium dark:text-gray-100">{@label}</span>
      <.docs_info :if={@docs} slug={@docs} />
      <.tooltip :if={@tooltip} centered?={true}>
        <:tooltip_content>{@tooltip}</:tooltip_content>
        <Heroicons.information_circle class="size-4.5 text-gray-400 dark:text-gray-500" />
      </.tooltip>
    </div>
    """
  end

  def settings_divider(assigns) do
    ~H"""
    <hr class="border-gray-200 dark:border-gray-700" />
    """
  end
end
