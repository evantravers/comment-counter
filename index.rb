require 'sinatra'
require 'haml'
require 'sass'
require 'compass'
require 'yaml'
require 'pry'
require 'facebook_oauth'

# get all the config in
configure do
  enable :sessions
  @@config = YAML.load_file('config.yml') rescue nil || {}
end

before do
  next if request.path_info =~ /ping$/
  @user = session[:user]
  @client = FacebookOAuth::Client.new(
    :application_id => ENV['Id'] || @@config['Id'],
    :application_secret => ENV['Secret'] || @@config['Secret'],
    :callback => "http://#{ENV['URL'] || @@config['Hostname']}/callback",
    :token => session[:access_token]
  )
end

get '/' do
  haml :index
end

get '/auth' do
  redirect @client.authorize_url(:scope => '')
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

get '/logout' do
  session.delete(:user)
  redirect '/'
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
