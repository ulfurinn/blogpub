defmodule Blogpub.Webfinger do
  defmodule Resource do
    @derive Jason.Encoder

    defstruct [
      :subject,
      :links
    ]
  end

  def resource(uri) do
    with %URI{scheme: "acct", path: path} <- URI.parse(uri),
         [qname, domain] <- String.split(path, "@", parts: 2),
         true <- Blogpub.own_domain?(domain),
         true <- Blogpub.has_user?(qname) do
      %Resource{
        subject: "acct:" <> qname <> "@" <> Blogpub.domain(),
        links: [
          %{ref: "self", type: "application/activity+json", href: Blogpub.host() <> "/" <> qname}
        ]
      }
    else
      _ -> :not_found
    end
  end
end
