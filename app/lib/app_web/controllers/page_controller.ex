defmodule AppWeb.PageController do
  use AppWeb, :controller
  alias App.Auth
  alias App.Auth.User
  alias App.Auth.Guardian

  require Intercom

  plug :intercom

  def index(conn, _params) do
    changeset = Auth.change_user(%User{})
    user = Guardian.Plug.current_resource(conn)
    conn
      |> render("index.html", changeset: changeset, action: page_path(conn, :login), user: user)
  end

  def login(conn, %{"user" => %{"username" => username, "password" => password}}) do
    Auth.authenticate_user(username, password)
    |> login_reply(conn)
  end

  defp login_reply({:error, error}, conn) do
    conn
    |> put_flash(:error, error)
    |> redirect(to: "/")
  end

  defp login_reply({:ok, user}, conn) do
    conn
    |> put_flash(:success, "Welcome back!")
    |> Guardian.Plug.sign_in(user)
    |> redirect(to: "/")
  end

  def logout(conn, _) do
    conn
    |> Guardian.Plug.sign_out()
    |> redirect(to: page_path(conn, :login))
  end

  def secret(conn, _params) do
    render(conn, "secret.html")
  end

  def intercom(conn, _params) do
    is_user = Guardian.Plug.current_resource(conn)
    {:ok, snippet} =
      case is_user do
        nil ->
          Intercom.snippet(
            %{email: ""},
            app_id: "<intercom_app_id>",
            secret: "<intercom_secret>"
          )
        _ ->
          Intercom.snippet(
            %{email: is_user.email},
            app_id: "<intercom_app_id>",
            secret: "<intercom_secret>"
          )
      end
    assign(conn, :intercom, snippet)
  end
end
