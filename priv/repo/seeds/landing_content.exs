alias MaragaInfo.Content

landing_settings = %{
  "home.hero.bg_image" => "/images/IMG_2075.jpg",
  "home.hero.title" => "David Kenani Maraga -  2027",
  "home.hero.tagline" => "Reset. Restore. Rebuild Kenya.",
  "home.hero.cta1_label" => "Read More",
  "home.hero.cta1_href" => "#mission",
  "home.hero.cta2_label" => "Jiandikishe Kupiga Kura",
  "home.hero.cta2_href" => "https://www.iebc.or.ke/iebc/?constituency",
  "home.donate.button_url" => "https://donations.davidmaraga.com/",
  "home.donate.volunteer_url" => "https://www.davidmaraga.com/volunteer",
  "home.mission.image" => "/images/IMG_2052.jpg",
  "home.mission.heading_prefix" => "A man of",
  "home.mission.heading_accent1" => "integrity",
  "home.mission.heading_mid" => "for a time that demands",
  "home.mission.heading_accent2" => "character.",
  "home.mission.quote" =>
    "David Maraga — the judge who annulled a presidential election and proved no one is above the law. A reformer who digitized courts, expanded access to justice, and authored over 1,250 judgments. Fearless, principled, and relentless — Kenya's greatest judicial guardian",
  "home.mission.cta_href" => "#footer",
  "home.documentary.title_prefix" => "The Maraga Story",
  "home.documentary.title_accent" => "Documentary",
  "home.documentary.description" =>
    "The first autobiographical documentary on David Maraga, produced with NTV.",
  "home.documentary.youtube_url" => "https://www.youtube.com/embed/-2QefPbyXrQ",
  "home.news.title_prefix" => "latest",
  "home.news.title_accent" => "News",
  "home.news.description" =>
    "Get the latest updates on the campaign trail, policy positions, and more.",
  "home.newsletter.bg_image" => "/images/maraga-town-old.jpg",
  "home.newsletter.eyebrow" => "Stay in the loop",
  "home.newsletter.heading" => "Subscribe to the newsletter",
  "home.newsletter.description" =>
    "Get campaign updates, rally announcements, and policy highlights delivered straight to your inbox.",
  "home.newsletter.cta_href" => "#footer",
  "home.stats.eyebrow" => "Kenya 2027",
  "home.stats.heading" => "David Maraga",
  "home.stats.tagline" => "For President · Integrity · Justice · Nation",
  "home.stats.motto" => "Ukatiba Ndio Tiba",
  "home.stats.stat1_value" => "1,250",
  "home.stats.stat1_label" => "Judgments",
  "home.stats.stat1_description" => "Decisions that shaped Kenya's law",
  "home.stats.stat2_value" => "#1",
  "home.stats.stat2_label" => "In Africa",
  "home.stats.stat2_description" => "Annulled a presidential election",
  "home.stats.stat2_badge" => "Historic First",
  "home.stats.stat3_value" => "47",
  "home.stats.stat3_label" => "Counties",
  "home.stats.stat3_description" => "Justice delivered to every corner",
  "home.stats.stat4_value" => "0",
  "home.stats.stat4_label" => "Tolerance",
  "home.stats.stat4_description" => "For corruption & impunity",
  "home.agenda.title_prefix" => "Watch the",
  "home.agenda.title_accent" => "Campaign",
  "home.agenda.description" =>
    "Catch the latest moments from the trail — tap any clip to watch on YouTube and social media.",
  "home.events.title_prefix" => "Upcoming",
  "home.events.title_accent" => "Events",
  "home.events.description" =>
    "Follow the latest news and updates from the campaign trail ."
}

Content.upsert_settings(landing_settings)
IO.puts("Seeded #{map_size(landing_settings)} landing page settings.")
