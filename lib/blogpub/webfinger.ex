defmodule Blogpub.Webfinger do
  defmodule Resource do
    @derive Jason.Encoder

    defstruct [
      :subject,
      :links
    ]
  end

  defmodule Link do
    @derive Jason.Encoder

    defstruct [:rel, :type, :href]
  end

  def resource(uri) do
    with %URI{scheme: "acct", path: path} <- URI.parse(uri),
         [feed, domain] <- String.split(path, "@", parts: 2),
         true <- Blogpub.own_domain?(domain),
         true <- Blogpub.has_feed?(feed) do
      %Resource{
        subject: "acct:" <> feed <> "@" <> Blogpub.domain(),
        links: [actor_link(feed)]
      }
    else
      _ -> :not_found
    end
  end

  defp actor_link(feed) do
    %Link{
      rel: "self",
      type: "application/activity+json",
      href: Blogpub.APub.actor_url(feed)
    }
  end
end
