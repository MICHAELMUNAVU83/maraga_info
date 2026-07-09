defmodule MaragaInfo.Volunteers.WelcomeNotifier do
  @moduledoc """
  Sends the welcome email to newly subscribed newsletter recipients.
  """
  import Swoosh.Email

  alias MaragaInfo.Campaigns.CampaignEmail
  alias MaragaInfo.Mailer

  @sections [
    %{
      "type" => "greeting",
      "eyebrow" => "Welcome",
      "title" => "Thank You For Joining Us!",
      "greeting" => "Hi {{first_name}},"
    },
    %{
      "type" => "text",
      "body" =>
        "I'm excited to welcome you to our campaign community and grateful you've chosen to be part of this journey. Together, we're building a movement that believes in honest leadership, integrity, accountability and a better future for all Kenyans."
    },
    %{
      "type" => "image",
      "url" => "/images/gallery/1.jpg",
      "alt" => "David Maraga greeting supporters on the campaign trail"
    },
    %{
      "type" => "text",
      "body" =>
        "You'll hear from us with campaign updates, opportunities to get involved, and ways you can help make a real difference."
    },
    %{
      "type" => "text",
      "body" => "Thank you for standing with us. I'm excited to have you on the team."
    },
    %{
      "type" => "signature",
      "salutation" => "Warmly,",
      "name" => "David Maraga",
      "tagline" => "Reset.Restore.Rebuild Kenya"
    }
  ]

  @preheader "Thank you for joining us!"

  def deliver_welcome_email(email, name \\ nil) when is_binary(email) do
    {from_name, from_email} =
      Application.get_env(
        :maraga_info,
        :mail_from,
        {"David Maraga Campaign", "no-reply@davidmaraga.info"}
      )

    recipient = %{email: email, name: name}
    content = %{sections: @sections, preheader: @preheader}

    message =
      new()
      |> to(email)
      |> from({from_name, from_email})
      |> subject("Thank you for joining us!")
      |> html_body(CampaignEmail.render_html(content, recipient))
      |> text_body(CampaignEmail.render_text(content, recipient))

    with {:ok, _metadata} <- Mailer.deliver(message) do
      {:ok, message}
    end
  end
end
