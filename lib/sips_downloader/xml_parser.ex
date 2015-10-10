defmodule SipsDownloader.XMLParser do
  require Record

  Record.defrecord :xmlElement, Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlAttribute, Record.extract(:xmlAttribute, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlText, Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")

  def parse_login_url(string) do
    string
    |> Floki.find("form")
    |> Floki.attribute("action")
    |> Enum.at(0)
  end

  def parse_episodes(feed) do
    feed
    |> to_xml
    |> episode_descriptions
    |> Enum.map(&normalize_string/1)
    |> Enum.map(&parse_episode_title_and_link/1)
    |> List.flatten
  end

  def to_xml(str) do
    String.replace(str, ~r/&.*;/, "")
    |> :erlang.binary_to_list
    |> :xmerl_scan.string
    |> elem(0)
  end

  def episode_descriptions(xml) do
    ~c{//channel/item/description/text()}
    |> :xmerl_xpath.string(xml)
    |> Enum.map(&(xmlText(&1, :value)))
    |> Enum.map(&normalize_string/1)
  end

  def normalize_string(string) do
    string
    |> to_string
    |> String.split(["\n"])
    |> Enum.map(&String.strip/1)
    |> Enum.join("")
  end

  def parse_episode_title_and_link(episode_description) do
    attached_files_part =
      episode_description
      |> String.split("<h3>Attached Files</h3>")
      |> List.last

    episode_xml = to_xml("<div>" <> attached_files_part)

    link_elems = '//ul/li/a' |> :xmerl_xpath.string(episode_xml)

    Enum.map(link_elems, fn (link_elem) ->
      {get_link_title(link_elem), get_link_href(link_elem)}
    end)
  end

  def get_link_title(link_elem) do
    link_elem
    |> xmlElement(:content)
    |> List.first
    |> xmlText(:value)
    |> to_string
    |> String.strip
  end

  def get_link_href(link_elem) do
    link_elem
    |> xmlElement(:attributes)
    |> Enum.find(&(:href == xmlAttribute(&1, :name)))
    |> xmlElement(:content)
    |> to_string
  end
end
