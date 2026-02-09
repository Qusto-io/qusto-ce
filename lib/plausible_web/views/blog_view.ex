defmodule PlausibleWeb.BlogView do
  use PlausibleWeb, :view

  import Phoenix.HTML, only: [raw: 1]

  def format_date(date) do
    Calendar.strftime(date, "%B %d, %Y")
  end
end
