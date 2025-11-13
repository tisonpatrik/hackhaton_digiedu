defmodule LiveDashboardWeb.LocaleController do
  use LiveDashboardWeb, :controller

  def set(conn, %{"locale" => locale}) when locale in ["en", "cs"] do
    # Get the referer or default to root
    referer = get_req_header(conn, "referer")
    redirect_path =
      if referer != [] do
        uri = URI.parse(hd(referer))
        uri.path || ~p"/"
      else
        ~p"/"
      end

    conn
    |> put_session("locale", locale)
    |> redirect(to: redirect_path)
  end

  def set(conn, _params) do
    redirect(conn, to: ~p"/")
  end
end
