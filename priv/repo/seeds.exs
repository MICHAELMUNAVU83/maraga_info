# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MaragaInfo.Repo.insert!(%MaragaInfo.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias MaragaInfo.Accounts
alias MaragaInfo.Accounts.User
alias MaragaInfo.Content
alias MaragaInfo.Content.MediaItem
alias MaragaInfo.Content.Post
alias MaragaInfo.Repo
alias MaragaInfo.Volunteers

# --- Seed an admin user -----------------------------------------------------
# The first registered user is automatically promoted to admin by the
# registration changeset, so this account can manage the blog at /admin.
admin_email = "admin@davidmaraga.info"

admin =
  case Repo.get_by(User, email: admin_email) do
    nil ->
      {:ok, user} =
        Accounts.register_user(%{
          email: admin_email,
          password: "123456"
        })

      user

    user ->
      user
  end

# Ensure the seeded account can manage the blog at /admin.
admin =
  if admin.is_admin do
    admin
  else
    admin
    |> Ecto.Changeset.change(is_admin: true)
    |> Repo.update!()
  end

# --- Seed volunteers -------------------------------------------------------
volunteer_seed_path = Path.join([__DIR__, "seeds", "volunteers_2026-05-11.xlsx"])

if File.exists?(volunteer_seed_path) do
  case Volunteers.import_volunteers_from_file(volunteer_seed_path) do
    {:ok, summary} ->
      IO.puts(
        "Seeded volunteers: #{summary.inserted} added, #{summary.updated} updated, #{summary.failed} failed."
      )

    {:error, reason} ->
      IO.puts("Skipping volunteer seed import: #{inspect(reason)}")
  end
end

# --- Seed blog posts --------------------------------------------------------
posts = [
  %{
    title: "David Maraga declares 2027 presidential bid: Reset, Restore, Rebuild",
    slug: "david-maraga-declares-2027-presidential-bid",
    category: "Latest News",
    seo_description:
      "David Maraga, Kenya's former Chief Justice, has declared his 2027 presidential bid on a platform to Reset, Restore and Rebuild Kenya. Read what his candidacy means.",
    image_url: "/images/maxresdefault.jpg",
    body:
      "Maraga framed his candidacy as a citizen-driven movement rather than a conventional political launch, telling supporters his mission is to \"Reset, Restore and Rebuild\" the country.\n\nFor a man best known for defending the constitution from the bench, the move marks a deliberate shift from interpreting the law to seeking the mandate to govern.",
    status: :published,
    published_at: ~U[2025-06-18 10:00:00Z],
    is_featured: true,
    user_id: admin.id,
    sections: [
      %{
        position: 0,
        heading: "From the bench to the ballot",
        body:
          "David Maraga served as Kenya's 14th Chief Justice between October 2016 and January 2021. His decision to seek elective office places one of the country's most recognised defenders of judicial independence directly into competitive politics.\n\nHe has positioned himself as a candidate built on integrity and the rule of law, arguing that Kenya's challenges are less about resources and more about leadership and accountability. Where many campaigns lead with promises of new projects, Maraga has led with a promise of new conduct: a government that obeys its own laws.\n\nThat framing is intentional. Having spent his career insisting that power must answer to the constitution, he is now asking voters to let him hold executive power to the same standard from the inside.",
        image_urls: ["/images/gallery/2.jpg"]
      },
      %{
        position: 1,
        heading: "A government of professionals",
        body:
          "Central to Maraga's pitch is the promise of a government of professionals and experts, with appointments made on competence and accountability rather than political patronage.\n\nHe has said only qualified and ethical individuals would serve in his administration, casting the 2027 contest as a choice between business-as-usual politics and a values-driven reset.\n\nMaraga argues that corruption and impunity are not abstract problems but the direct cost of putting loyalty above merit. His answer is a leaner state staffed by people chosen for what they can do, not who they know.",
        image_urls: []
      },
      %{
        position: 2,
        heading: "What comes next",
        body:
          "Declaring a bid is only the first step. In the months that follow, Maraga's team has set out to build a national structure, popularise the movement county by county, and translate goodwill into the organised support a presidential campaign requires.\n\nThe early signs suggest a campaign that wants to be defined less by rallies and slogans than by a clear governing philosophy. Whether that approach can compete with Kenya's established political machines is the central question of his candidacy.",
        image_urls: []
      }
    ]
  },
  %{
    title: "Citizen-led drive raises Sh8 million for Maraga's 2027 campaign",
    slug: "citizen-led-drive-raises-sh8-million-for-maraga-2027-campaign",
    category: "Latest News",
    seo_description:
      "David Maraga's citizen-led 2027 campaign fund has raised roughly Sh8 million from over 1,800 contributors, including the Kenyan diaspora. Here is what the numbers show.",
    image_url: "/images/IMG_2028.jpg",
    body:
      "The Maraga '27 platform lets supporters contribute amounts as small as Sh50, framing the bid as a people-driven movement to fund grassroots mobilisation, town halls and digital outreach.\n\nBy April 2026, the drive had raised roughly Sh8 million from more than 1,800 individual contributors, with a notable share coming from the Kenyan diaspora.",
    status: :published,
    published_at: ~U[2026-04-08 09:00:00Z],
    is_featured: false,
    user_id: admin.id,
    sections: [
      %{
        position: 0,
        heading: "Funding the people's way",
        body:
          "Rather than rely on a handful of deep-pocketed financiers, the campaign has built a contribution platform open to ordinary citizens. Supporters can give as little as Sh50, a deliberate choice meant to keep ownership of the bid with voters.\n\nCampaign organisers say the model is designed to protect the candidate's independence and to demonstrate broad-based support ahead of the polls. A candidate who owes his campaign to thousands of small donors, the thinking goes, owes nothing to any single patron.\n\nIt is also a test of message. If a campaign built on integrity cannot raise money cleanly, the argument loses force. The early returns are being read by Maraga's team as proof of concept.",
        image_urls: ["/images/gallery/3.jpg"]
      },
      %{
        position: 1,
        heading: "What the money will do",
        body:
          "Contributions are earmarked for grassroots mobilisation, campaign events and town halls, digital outreach and a national network of volunteers.\n\nFor Maraga's team, the early momentum is as much a message as it is a war chest: proof that a campaign anchored on integrity can be financed by the public it hopes to serve.\n\nThe diaspora's role has been notable. Kenyans abroad, often among the most vocal critics of corruption back home, have given the campaign both money and a sense that its appeal reaches beyond any single region or constituency.",
        image_urls: []
      },
      %{
        position: 2,
        heading: "A long road to 2027",
        body:
          "Eight million shillings is modest against the cost of a national campaign, and Maraga's team is candid that the figure matters more as a signal than as a sum.\n\nThe goal over the coming months is to widen the base of contributors, deepen the volunteer network, and convert online enthusiasm into the ground organisation that ultimately wins votes. The fundraising drive is, in that sense, the opening argument of the campaign rather than its conclusion.",
        image_urls: []
      }
    ]
  },
  %{
    title: "The 2017 election annulment that still defines David Maraga",
    slug: "the-2017-election-annulment-that-still-defines-david-maraga",
    category: "Analysis",
    seo_description:
      "Analysis of the September 1, 2017 Supreme Court ruling, led by Chief Justice David Maraga, that annulled Kenya's presidential election and reshaped his public legacy.",
    image_url: "/images/IMG_2075.jpg",
    body:
      "The Supreme Court annulled President Uhuru Kenyatta's August 8 election win, citing irregularities in how the IEBC transmitted results, and ordered a fresh poll within 60 days.\n\nFour of the six justices supported Raila Odinga's petition, making it the first time an African court had nullified the re-election of a sitting president.",
    status: :published,
    published_at: ~U[2017-09-01 12:00:00Z],
    is_featured: false,
    user_id: admin.id,
    sections: [
      %{
        position: 0,
        heading: "A historic first for the continent",
        body:
          "The ruling established that the integrity of the electoral process mattered as much as the headline vote tally. The court held that irregularities and illegalities in the transmission of results had compromised the credibility of the outcome.\n\nNo African court had previously overturned the victory of an incumbent president, and the decision drew worldwide attention to Kenya's judiciary. Legal scholars across the world cited it as evidence that courts in young democracies could enforce constitutional limits even against the most powerful office in the land.\n\nThe message was as much about process as about politics: an election is not merely a result to be announced, but a procedure that must be conducted lawfully and verifiably.",
        image_urls: ["/images/gallery/4.jpg"]
      },
      %{
        position: 1,
        heading: "Pressure and principle",
        body:
          "President Kenyatta publicly criticised the decision, at one point describing it as a problem with the judiciary, and Maraga and his colleagues faced intense political pressure.\n\nMaraga's insistence that courts must enforce the constitution regardless of who holds power became the defining theme of his tenure, and remains central to how Kenyans assess him today.\n\nThe period that followed tested the judiciary. Threats, funding fights and political hostility became part of the backdrop to Maraga's remaining years in office, yet the ruling stood. For supporters, that endurance is the point: institutions held because individuals refused to bend.",
        image_urls: []
      },
      %{
        position: 2,
        heading: "Why it still matters in 2027",
        body:
          "Years later, the annulment continues to shape how Kenyans see Maraga. To admirers it is proof that he will not trade principle for convenience; to critics it is a reminder of the political turbulence that followed.\n\nEither way, it is the lens through which his presidential bid is read. A candidacy built on the rule of law cannot escape the most famous example of that man enforcing it — and Maraga has not tried to. He has made it the cornerstone of his political identity.",
        image_urls: []
      }
    ]
  },
  %{
    title: "David Maraga biography: from Nyamira to Chief Justice and beyond",
    slug: "david-maraga-biography-from-nyamira-to-chief-justice",
    category: "Explainer",
    seo_description:
      "Biography of David Kenani Maraga: born 1951, University of Nairobi law graduate, 25 years in practice, judge, 14th Chief Justice of Kenya and 2027 presidential aspirant.",
    image_url: "/images/IMG_2052.jpg",
    body:
      "He earned Bachelor of Laws and Master of Laws degrees from the University of Nairobi and was admitted to the bar in 1978, spending some 25 years in private legal practice.\n\nHe was appointed a judge of the High Court in 2003, later served on the Court of Appeal, and became Kenya's 14th Chief Justice in October 2016, retiring in January 2021.",
    status: :published,
    published_at: ~U[2026-06-13 09:00:00Z],
    is_featured: false,
    user_id: admin.id,
    sections: [
      %{
        position: 0,
        heading: "Early life and legal career",
        body:
          "Maraga's path to the bench ran through decades of private practice before his 2003 appointment to the High Court. He graduated from the University of Nairobi and was admitted to the bar in 1978, then spent roughly a quarter of a century as a practising advocate.\n\nA devout Seventh-day Adventist, he is widely known for declining to work on the Sabbath, a personal discipline that became part of his public profile during his confirmation hearings. His refusal to compromise on that conviction, even under questioning, offered an early glimpse of the temperament he would carry to the Supreme Court.\n\nHis steady rise through the High Court and Court of Appeal built a reputation for careful, principled judgments and an unflashy commitment to the letter of the law.",
        image_urls: ["/images/gallery/1.jpg"]
      },
      %{
        position: 1,
        heading: "Chief Justice and constitutional guardian",
        body:
          "As Chief Justice and President of the Supreme Court from 2016 to 2021, Maraga championed judicial independence at moments of high political tension.\n\nHe also chaired the Judicial Service Commission and pushed for reforms to clear case backlogs and protect the courts from political interference. He repeatedly clashed with the executive over funding for the judiciary and the appointment of judges, framing those fights as battles over the separation of powers rather than personal disputes.\n\nIt was during this period that the 2017 election annulment cemented his national and international standing as a judge willing to rule against power.",
        image_urls: ["/images/gallery/5.jpg"]
      },
      %{
        position: 2,
        heading: "A new chapter in public life",
        body:
          "After retiring in 2021 upon reaching the constitutional retirement age, Maraga largely stayed out of the spotlight before announcing his 2027 presidential bid in June 2025.\n\nHis candidacy ties his judicial record on accountability and the rule of law to a broader political message about resetting and rebuilding Kenya. In effect, he is asking voters to extend the trust they once placed in his judgments to the work of governing.\n\nWhether Kenyans embrace that pitch will be decided at the ballot in 2027. What is already clear is that the man who annulled a presidency now wants to hold one.",
        image_urls: []
      }
    ]
  }
]

Enum.each(posts, fn attrs ->
  case Repo.get_by(Post, slug: attrs.slug) do
    nil -> Content.create_post(attrs)
    _post -> :ok
  end
end)

# --- Seed gallery media items -----------------------------------------------
# These five images power the home page gallery collage, fetched in order of
# their position from the media_items table.
media_items = [
  %{
    title: "On the campaign trail",
    description: "David Maraga greeted by supporters during a county tour.",
    category: "Rallies",
    image_url: "/images/gallery/1.jpg",
    display_on_landing: true,
    position: 0
  },
  %{
    title: "Welcoming a newborn",
    description: "A warm moment with a young family at a community visit.",
    category: "Public",
    image_url: "/images/gallery/2.jpg",
    display_on_landing: true,
    position: 1
  },
  %{
    title: "Greeted by the crowds",
    description: "Crowds turn out to receive Maraga on the streets.",
    category: "Rallies",
    image_url: "/images/gallery/3.jpg",
    display_on_landing: true,
    position: 2
  },
  %{
    title: "With the next generation",
    description: "Maraga shares a light moment with a young supporter.",
    category: "Public",
    image_url: "/images/gallery/4.jpg",
    display_on_landing: true,
    position: 3
  },
  %{
    title: "Speaking to the press",
    description: "Maraga addresses the media during a campaign stop.",
    category: "Press",
    image_url: "/images/gallery/5.jpg",
    display_on_landing: true,
    position: 4
  }
]

Enum.each(media_items, fn attrs ->
  case Repo.get_by(MediaItem, image_url: attrs.image_url) do
    nil -> Content.create_media_item(attrs)
    item -> Content.update_media_item(item, attrs)
  end
end)
