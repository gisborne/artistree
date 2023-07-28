ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'minitest/autorun'
require 'minitest/spec'
require_relative 'artistree.rb' # the filename of your Sinatra app

include Rack::Test::Methods

def app
  Sinatra::Application
end

describe 'ArtisTree App' do
  it 'should load the home page' do
    get '/'
    assert last_response.ok?
  end

  it 'should post to search page' do
    post '/search', { 'q' => 'Eminem' }
    assert last_response.ok?
  end

  it 'should fail on non-existent artist' do
    post '/search', { 'q' => 'fake artist' }
    assert last_response.ok?
  end

  it 'should find "Bohemian Rhapsody" when searching for "Queen"' do
    post '/search', { 'q' => 'Queen' }
    assert last_response.ok?
    assert last_response.body.include?("Bohemian Rhapsody")
  end
end
