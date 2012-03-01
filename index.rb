require 'sinatra'
require 'haml'
require 'sass'
require 'compass'
require 'yaml'
require 'pry'


keys = YAML::load(File.read('config.yml'))
Id = keys['facebook']['id'].to_i
Secret = keys['facebook']['secret']

get '/' do
  haml :index
end

# facebook is sending us magic
get '/?code=*' do
  @code = params[:splat]
  binding.pry
  redirect '/'
  # TODO authenticate
  # https://graph.facebook.com/oauth/access_token?client_id=#{Id}&redirect_uri=#{request.url}&client_secret=#{Secret}&code=#{@code}
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
    not @code.nil?
  end
end
