require 'sinatra'
require 'httparty'
require 'json'
require 'i18n'

token = ENV['GENIUS_TOKEN']

I18n.config.available_locales = :en

get '/' do
  erb :page
end

post '/search' do
  begin
    query = params[:q]
    url = "http://api.genius.com/search?q=#{URI.encode_www_form_component(query)}"
    headers = {'Authorization' => 'Bearer ' + token}
    response = HTTParty.get(url, headers: headers)
    simple_data = JSON.parse(response.body)
    @data = extract_data(simple_data, query)
    erb :page
  rescue Exception => e
    @data = e
    erb :error
  end
end

def extract_data simple_data, artist
  if simple_data['meta']['status'] != 200
    raise "Error: #{simple_data['meta']['status']}"
  end

  hits = simple_data['response']['hits']

  if hits.empty?
    return nil
  end

  result = hits
    .filter{|hit| accepted_entry(hit, artist)}
    .inject({}) do |results, hit|
      this_artist = hit['result']['artist_names']
      title = hit['result']['title']
      (results[this_artist] ||= []) << title
      results
  end
  .sort.to_h

  result.each_value do |titles|
      titles.sort!
    end
end

def accepted_entry e, artist
  e['type'] == 'song' &&
    simplify(e['result']['artist_names'])
      .downcase
      .include?(simplify(artist.downcase))
end

def simplify str
  I18n.transliterate str.downcase
end

__END__

@@page
<!doctype html>
<html>
  <head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css">
  <title>ArtisTree</title>
  </head>
  <body>
  <section class="section">
    <div class="container">
    <img src="https://i.genius.com/27195801ae270a0a4394374e51bc9fd9a5687f37?url=https%3A%2F%2Fvectorportal.com%2Fstorage%2Fs-girlspeak_5562.jpg" alt="ArtisTree" width="90" height="80">
    <h1>ArtisTree</h1>
    <div class="box">
    <form action="/search" method="post">
      <input type="text" name="q" required>
      <input type="submit" value="Search">
    </form>
    </div>
    <% if @data && !@data.empty? %>
    <table class="table is-striped">
    <tr>
    <th>Artist</th>
    <th>Songs</th>
    </tr>
    <% @data.each do |artist, songs| %>
    <tr>
    <td class="p-2"><%= artist %></td>
    <td><%= songs.join('<br>') %></td>
    </tr>
    <% end %>
    </table>
    <% end %>
    </div>
  </section>
  </body>
</html>

@@error
<!doctype html>
<html>
  <body>
    <form action="/search" method="post">
      <input type="text" name="q" required>
      <input type="submit" value="Search">
    </form>
    <pre><%= @data %></pre>
  </body>
</html>