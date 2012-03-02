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
  @post_id = params[:id]
  @request = "https://graph.facebook.com/#{@post_id}/comments?access_token=#{session[:access_token]}"
  @json = JSON.parse HTTParty.get(@request).response.body
  @words = {}
  # while there is data
  until @json['data'].empty?
    @json['data'].each do | comment |
      words = comment.split(/\W+/)
      words.each do |word|
        if @words.has_key?(word)
          @words[word] = @words[word]+1
        else
          @words[word] = 1
        end
      end
    end
    # follow the paging link
    @request = @json['paging']['next']
    @json = JSON.parse HTTParty.get(@request).response.body
  end
  @words = @words.to_a.sort_by! {|k,v| v}.reverse
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
