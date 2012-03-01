require 'sinatra'
require 'haml'
require 'sass'
require 'compass'

# facebook is sending us magic
get '/?code=*' do
  @code = params[:splat]
  # TODO authenticate
  # https://graph.facebook.com/oauth/access_token?client_id=343543839017091&redirect_uri=#{request.url}&client_secret=c78c34e1056c2ba6b33238fa50088c13&code=#{@code}
end

get '*?error_reason*' do
  haml :error
end

get '/' do
  haml :index
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
