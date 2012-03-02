require 'sinatra'
require 'haml'
require 'sass'
require 'compass'
require 'yaml'
require 'pry'
require 'facebook_oauth'

enable :sessions

# get all the config in
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

before do
  next if request.path_info =~ /ping$/
  @user = session[:user]
  @client = FacebookOAuth::Client.new (
    :application_id => Id
    :application_secret => Secret
    :callback => Hostname
    :token => session[:access_token]
  )
end

get '/' do
  haml :index
end

get '/auth' do
  reirect @client.authorize_url
end

get '/callback' do
  access_token = @client.authorize(:code => params[:code])
  session[:access_token] = access_token.token
  session[:user] = @client.me.info['name']
  redirect '/'
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
    not session[:access_token].nil?
  end
end
