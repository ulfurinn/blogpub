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
         [name, feed] <- String.split(qname, "-", parts: 2),
         true <- domain in [domain(), pub_domain()],
         true <- name == username(),
         true <- feed in feed_names() do
      %Resource{
        subject: "acct:" <> qname <> "@" <> domain(),
        links: [%{ref: "self", type: "application/activity+json", href: host() <> "/" <> qname}]
      }
    else
      _ -> :not_found
    end
  end

  def host, do: Application.get_env(:blogpub, :host)
  def domain, do: Application.get_env(:blogpub, :domain)
  def pub_domain, do: Application.get_env(:blogpub, :pub_domain) || domain()
  def username, do: Application.get_env(:blogpub, :username)
  def feeds, do: Application.get_env(:blogpub, :feeds)
  def feed_names, do: feeds() |> Map.keys()
end
