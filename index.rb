require 'sinatra'
require 'haml'
require 'sass'
require 'compass'


get '/' do
  haml :index
end

post '/' do
  @post = params[:post]
  haml :success
end

# style sheet rules
get '/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end
