alias MaragaInfo.Campaigns
alias MaragaInfo.Campaigns.EmailCampaign
alias MaragaInfo.Campaigns.NewsletterBuilder
alias MaragaInfo.Repo

# --- Seed base email campaign -------------------------------------------
campaign_subject = "Building a Kenya Rooted in Integrity & Justice"
campaign_preheader =
  "Integrity, justice and service for Kenya — your weekly briefing from the Maraga 2027 movement."

campaign_sections = [
  %{
    "type" => "image",
    "url" => "https://davidmaraga.info/images/maraga-town.jpg",
    "alt" => "David Maraga on the campaign trail",
    "link_url" => "https://davidmaraga.info/"
  },
  %{
    "type" => "greeting",
    "eyebrow" => "This week on the trail",
    "title" => "Building a Kenya Rooted in Integrity & Justice",
    "greeting" => "Hello <strong style=\"color:#026631\">{{first_name}}</strong>,"
  },
  %{
    "type" => "text",
    "body" =>
      "Thank you for standing with the movement during another momentous week on the trail. We crossed counties from the coast to the highlands, sat with grassroots organizers, and listened closely to the hopes and frustrations of ordinary Kenyans. Together we laid out the next stage of our agenda for constitutional leadership, rooted firmly in integrity, justice and service. Every conversation reaffirmed why this cause matters and why your voice carries it forward. Below is what mattered most this week — the moments that moved us and the milestones we reached as one community. Read on to see how you can be part of everything that comes next."
  },
  %{
    "type" => "highlights",
    "label" => "Highlights this week",
    "items" => [
      "Town hall in Westlands drew over 1,200 supporters calling for accountable governance.",
      "New campaign pillar unveiled: an independent judiciary free from political capture.",
      "Volunteer drive expanded to 12 new counties — sign up to lead your ward."
    ]
  },
  %{
    "type" => "cta",
    "url" => "https://donations.davidmaraga.com/",
    "label" => "I Would Like to Donate",
    "subtext" => "Every contribution powers grassroots organizing across Kenya."
  },
  %{
    "type" => "signature",
    "salutation" => "With gratitude,",
    "name" => "The Maraga 2027 Team",
    "tagline" => "Integrity · Justice · Service"
  }
]

campaign_body =
  NewsletterBuilder.build_html(campaign_sections,
    preheader: campaign_preheader,
    date: "22 June, 2026"
  )

case Repo.get_by(EmailCampaign, subject: campaign_subject) do
  nil ->
    Campaigns.create_campaign(%{
      subject: campaign_subject,
      sender_name: "David Maraga Campaign",
      sender_title: "Campaign Newsletter",
      preheader: campaign_preheader,
      reply_to: "info@davidmaraga.info",
      body: campaign_body,
      sections: campaign_sections
    })

    IO.puts("Seeded base email campaign: #{campaign_subject}")

  _campaign ->
    IO.puts("Skipping email campaign seed — already exists.")
end
