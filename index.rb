require 'sinatra'
require 'haml'
require 'sass'
require 'compass'
require 'yaml'
require 'pry'
require 'uri'


enable :sessions

keys = YAML::load(File.read('config.yml'))
Id = keys['facebook']['id'].to_i
Secret = keys['facebook']['secret']
Hostname = keys['facebook']['hostname']

get '/' do
  # facebook magic
  if params['code']
    @code = params['code']
    redirect to("https://graph.facebook.com/oauth/access_token?client_id=#{Id}&redirect_uri=http://#{Hostname}:4567&client_secret=#{Secret}&code=#{@code}")
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
