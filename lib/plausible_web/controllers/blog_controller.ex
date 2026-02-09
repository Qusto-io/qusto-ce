defmodule PlausibleWeb.BlogController do
  use PlausibleWeb, :controller

  alias Plausible.Blog

  plug PlausibleWeb.RequireLoggedOutPlug

  def index(conn, _params) do
    render(conn, "index.html",
      posts: Blog.all_posts(),
      page_title: "Blog - Qusto Analytics",
      layout: {PlausibleWeb.LayoutView, "app.html"}
    )
  end

  def show(conn, %{"id" => id}) do
    post = Blog.get_post_by_id!(id)

    render(conn, "show.html",
      post: post,
      page_title: "#{post.title} - Qusto Blog",
      layout: {PlausibleWeb.LayoutView, "app.html"}
    )
  end
end
