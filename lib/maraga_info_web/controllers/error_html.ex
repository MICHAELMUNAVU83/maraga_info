defmodule MaragaInfoWeb.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.

  See config/config.exs.
  """
  use MaragaInfoWeb, :html

  def render("400.html", assigns) do
    error_page(
      Map.merge(assigns, %{
        code: "400",
        title: "Bad Request",
        message:
          "Something about that request wasn't quite right, so we couldn't process it. Please check the link and try again."
      })
    )
  end

  def render("404.html", assigns) do
    error_page(
      Map.merge(assigns, %{
        code: "404",
        title: "Page Not Found",
        message:
          "The page you're looking for may have been moved or no longer exists. Let's get you back on track."
      })
    )
  end

  def render("500.html", assigns) do
    error_page(
      Map.merge(assigns, %{
        code: "500",
        title: "Something Went Wrong",
        message:
          "An unexpected error occurred on our end. Our team has been notified — please try again in a moment."
      })
    )
  end

  # Fallback for any status without a dedicated template: render a plain text
  # page based on the template name. For example, "403.html" becomes "Forbidden".
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end

  attr :code, :string, required: true
  attr :title, :string, required: true
  attr :message, :string, required: true

  @doc """
  Renders a standalone, branded error page.

  Error responses are rendered without the application layout, so this template
  is a complete HTML document with inline styles to guarantee correct styling.
  """
  def error_page(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="robots" content="noindex" />
        <title>{@code} · {@title} | David Maraga Info</title>
        <style>
          * { box-sizing: border-box; margin: 0; padding: 0; }
          body {
            font-family: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
            color: #222222;
            background-color: #026631;
            background-image:
              radial-gradient(circle at 20% 20%, rgba(255,255,255,0.10), transparent 45%),
              radial-gradient(circle at 80% 80%, rgba(0,0,0,0.18), transparent 45%);
          }
          .card {
            width: 100%;
            max-width: 560px;
            background: #ffffff;
            border-radius: 14px;
            box-shadow: 0 30px 70px rgba(0,0,0,0.30);
            padding: 48px 40px;
            text-align: center;
          }
          .logo { height: 56px; width: auto; margin: 0 auto 28px; display: block; }
          .code {
            font-size: 84px;
            line-height: 1;
            font-weight: 800;
            letter-spacing: 2px;
            color: #026631;
          }
          .bar {
            width: 64px;
            height: 5px;
            border-radius: 999px;
            background: #CBC527;
            margin: 20px auto 24px;
          }
          .title {
            font-size: 26px;
            text-transform: uppercase;
            letter-spacing: 1px;
            font-weight: 700;
            color: #026631;
          }
          .message {
            margin-top: 14px;
            font-size: 16px;
            line-height: 1.7;
            color: #5b6470;
          }
          .button {
            display: inline-block;
            margin-top: 32px;
            padding: 14px 32px;
            border-radius: 999px;
            background: #026631;
            color: #ffffff;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 1.5px;
            font-size: 13px;
            text-decoration: none;
            transition: background 0.2s ease;
          }
          .button:hover { background: #014d25; }
          @media (max-width: 480px) {
            .card { padding: 36px 24px; }
            .code { font-size: 64px; }
          }
        </style>
      </head>
      <body>
        <main class="card">
          <img src="/images/logo.png" alt="David Maraga Info" class="logo" />
          <div class="code">{@code}</div>
          <div class="bar"></div>
          <h1 class="title">{@title}</h1>
          <p class="message">{@message}</p>
          <a href="/" class="button">Back to homepage</a>
        </main>
      </body>
    </html>
    """
  end
end
