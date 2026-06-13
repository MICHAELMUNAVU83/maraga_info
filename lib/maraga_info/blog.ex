defmodule MaragaInfo.Blog do
  @moduledoc false

  @profile %{
    name: "David Maraga",
    title: "Former Chief Justice of Kenya",
    summary:
      "David Kenani Maraga is a Kenyan lawyer and jurist who served as the 14th Chief Justice of Kenya from October 19, 2016 to January 12, 2021.",
    highlights: [
      "Served as Kenya's 14th Chief Justice and President of the Supreme Court.",
      "Became globally known after the Supreme Court annulled Kenya's August 2017 presidential election.",
      "Built a public reputation around judicial independence, integrity and constitutional accountability."
    ]
  }

  @timeline [
    %{
      date: "Oct 19, 2016",
      title: "Sworn in as Chief Justice",
      description:
        "David Maraga took office as Kenya's 14th Chief Justice after approval by the National Assembly."
    },
    %{
      date: "Sep 1, 2017",
      title: "Election annulment ruling",
      description:
        "The Supreme Court nullified the August 2017 presidential election, making Maraga the face of one of Africa's most consequential judicial decisions."
    },
    %{
      date: "Jan 12, 2021",
      title: "Retired from the Judiciary",
      description:
        "Maraga retired upon reaching the constitutional retirement age, closing a term defined by high-stakes constitutional disputes."
    },
    %{
      date: "Jun 8, 2026",
      title: "Detained at Nairobi National Park protest",
      description:
        "AP reported that Maraga was briefly detained and later released while protesting planned construction inside Nairobi National Park."
    }
  ]

  @coverage_focus [
    %{
      title: "Biography",
      body:
        "Track the core facts of Maraga's life, legal training, rise through the High Court and Court of Appeal, and tenure as Chief Justice."
    },
    %{
      title: "Judicial legacy",
      body:
        "Follow reporting and analysis on the 2017 election ruling, constitutionalism, court independence and integrity in public office."
    },
    %{
      title: "Current developments",
      body:
        "Monitor recent statements, civic appearances and major public-interest stories in which Maraga remains a visible national figure."
    }
  ]

  @posts [
    %{
      slug: "david-maraga-detained-at-nairobi-national-park-protest",
      date: "Jun 8, 2026",
      iso_date: "2026-06-08",
      category: "Latest News",
      title: "David Maraga detained during Nairobi National Park protest",
      excerpt:
        "AP reported that former Chief Justice David Maraga was briefly detained and later released during protests over planned construction inside Nairobi National Park.",
      seo_description:
        "Latest reporting on David Maraga's June 8, 2026 detention during protests over planned construction inside Nairobi National Park.",
      image: "/images/IMG_2075.jpg",
      intro:
        "On June 8, 2026, David Maraga re-entered national headlines when he joined protesters opposing planned construction inside Nairobi National Park. AP reported that he was detained and later released after attempting to present a petition to the Kenya Wildlife Service.",
      sections: [
        %{
          heading: "Why the protest mattered",
          body:
            "The demonstration centered on fears that public land and a protected environmental space were being altered without adequate public participation. The story linked Maraga's long-running public image on integrity to a fresh dispute about conservation, transparency and public accountability."
        },
        %{
          heading: "Why it drew attention",
          body:
            "Because Maraga is still widely identified with the Judiciary and constitutionalism, his appearance at the protest immediately elevated the story beyond an environmental demonstration. The episode also showed that his public profile now extends well beyond his years on the bench."
        }
      ]
    },
    %{
      slug: "why-the-2017-election-ruling-still-defines-maraga",
      date: "Sep 1, 2017",
      iso_date: "2017-09-01",
      category: "Analysis",
      title: "Why the 2017 election ruling still defines Maraga",
      excerpt:
        "The Supreme Court decision to annul Kenya's August 2017 presidential election remains the most cited moment of David Maraga's career.",
      seo_description:
        "Analysis of the 2017 Supreme Court ruling that made David Maraga one of Kenya's most consequential judges.",
      image: "/images/maxresdefault.jpg",
      intro:
        "For many Kenyans and international observers, David Maraga's legacy begins with the Supreme Court ruling of September 1, 2017. The court nullified the presidential election and ordered a fresh vote, a decision that reshaped how Maraga was understood at home and abroad.",
      sections: [
        %{
          heading: "A defining test of judicial independence",
          body:
            "The judgment signaled that electoral disputes could be resolved through constitutional processes rather than raw political power. It pushed Maraga into the center of debates about whether Kenyan institutions could act independently when the stakes were highest."
        },
        %{
          heading: "Why the ruling still matters in search and public memory",
          body:
            "Years later, searches for David Maraga are still strongly tied to the annulment. Any serious profile site about him needs to explain that ruling clearly because it remains the primary reason many readers, researchers and journalists look him up."
        }
      ]
    },
    %{
      slug: "david-maragas-retirement-and-judicial-legacy",
      date: "Jan 12, 2021",
      iso_date: "2021-01-12",
      category: "Background",
      title: "David Maraga's retirement and judicial legacy",
      excerpt:
        "Maraga retired from office on January 12, 2021, ending a term that kept judicial independence and constitutional limits in the national conversation.",
      seo_description:
        "Background on David Maraga's retirement from the office of Chief Justice and the legal legacy he left behind in 2021.",
      image: "/images/IMG_2052.jpg",
      intro:
        "David Maraga retired on January 12, 2021 after reaching the constitutional retirement age. By the time he left office, his name had become closely associated with court independence, anti-corruption messaging and the willingness to confront executive pressure.",
      sections: [
        %{
          heading: "What his tenure left behind",
          body:
            "Maraga's years in office are frequently discussed through the lens of constitutional fidelity and the role of courts in checking political power. Even critics generally acknowledge that his term raised the public visibility of the Judiciary as an independent arm of government."
        },
        %{
          heading: "Why retirement did not end the story",
          body:
            "Retirement moved Maraga out of formal office, but not out of public debate. His name still surfaces in discussions on integrity, governance, civil liberties and the long tail of major constitutional decisions."
        }
      ]
    },
    %{
      slug: "david-maraga-biography-career-and-key-facts",
      date: "Jun 13, 2026",
      iso_date: "2026-06-13",
      category: "Explainer",
      title: "David Maraga biography: career, record and key facts",
      excerpt:
        "A concise explainer on who David Maraga is, where he served and why he remains a major figure in Kenya's legal and political history.",
      seo_description:
        "Biography of David Maraga covering his legal career, Chief Justice tenure, retirement and enduring relevance in Kenyan public life.",
      image: "/images/gallery/1.jpg",
      intro:
        "David Kenani Maraga was born on January 12, 1951 and built a career through legal practice, the High Court, the Court of Appeal and eventually the Supreme Court. He is best known as the former Chief Justice whose public profile grew around questions of integrity, constitutionalism and judicial courage.",
      sections: [
        %{
          heading: "Core biography",
          body:
            "Maraga studied law at the University of Nairobi, entered legal practice and later joined the bench. He rose through senior judicial roles before being appointed Chief Justice in 2016."
        },
        %{
          heading: "Why he remains relevant",
          body:
            "Readers still search for Maraga because his record sits at the intersection of law, public ethics, elections and governance. A useful news page therefore needs both biography and up-to-date coverage, not one without the other."
        }
      ]
    }
  ]

  def all_posts, do: @posts
  def featured_post, do: hd(@posts)
  def profile, do: @profile
  def timeline, do: @timeline
  def coverage_focus, do: @coverage_focus

  def get_post(slug) do
    Enum.find(@posts, &(&1.slug == slug))
  end

  def adjacent_posts(slug) do
    index = Enum.find_index(@posts, &(&1.slug == slug))

    if is_nil(index) do
      {nil, nil}
    else
      {Enum.at(@posts, index - 1), Enum.at(@posts, index + 1)}
    end
  end
end
