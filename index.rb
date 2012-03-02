require 'sinatra'
require 'haml'
require 'sass'
require 'yaml'
require 'pry'
require 'pp'
require 'facebook_oauth'
require 'json'
require 'httparty'

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
  redirect @client.authorize_url(:scope => 'user_photos, friends_photos')
end

get '/callback' do
  access_token = @client.authorize(:code => params[:code])
  session[:access_token] = access_token.token
  session[:user] = @client.me.info['name']
  redirect '/'
end

post '/' do
  # append the data to the hash, follow the paging link
  @post_id = params[:id]
  @request = "https://graph.facebook.com/#{@post_id}/comments?access_token=#{session[:access_token]}"
  @json = JSON.parse HTTParty.get(@request).response.body
  # while there is data
  @messages
  while not @json['data'].empty?
    @json['data'].each do | comment |
      @messages.append comment['message']
    end
    @request = @json['paging']['next']
    @json = JSON.parse HTTParty.get(@request).response.body
  end
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
  def loggedin?
    not session[:user].nil?
  end
end
