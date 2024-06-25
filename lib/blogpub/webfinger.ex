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
         [qname, domain] <- String.split(path, "@", parts: 2),
         true <- Blogpub.own_domain?(domain),
         true <- Blogpub.has_user?(qname) do
      %Resource{
        subject: "acct:" <> qname <> "@" <> Blogpub.domain(),
        links: [actor_link(qname)]
      }
    else
      _ -> :not_found
    end
  end

  defp actor_link(qname) do
    %Link{
      rel: "self",
      type: "application/activity+json",
      href: Blogpub.APub.actor_url(qname)
    }
  end
end
