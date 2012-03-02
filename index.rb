require 'sinatra'
require 'haml'
require 'sass'
require 'compass'
require 'yaml'
require 'pry'
require 'uri'
require 'net/http'


enable :sessions

configure do
  if ENV['RACK_ENV'] != 'production'
    keys = YAML::load(File.read('config.yml'))
    Hostname = keys['facebook']['hostname']
    Id = keys['facebook']['id'].to_i
    Secret = keys['facebook']['secret']
  else
    Hostname = "http://#{ENV['URL']}"
    Id = ENV['Id']
    Secret = ENV['Secret']
  end
end

get '/' do
  # facebook magic
  if params['code']
    @code = params['code']
    # time to get the access token
    response = Net::HTTP.get_print URI.parse("https://graph.facebook.com/oauth/access_token?client_id=#{Id}&redirect_uri=#{Hostname}/&client_secret=#{Secret}&code=#{@code}")
  end
  haml :index
end

get '*?error_reason*' do
  haml :error
end

post '/' do
  @comment_id = params[:id]
  haml :success
end

# style sheet rules
get '/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

#helpers
helpers do
  def accesscode?
    not session[:code].nil?
  end
end
