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
  # what is the post ID
  @post_id = params[:id]
  # any specific search terms?
  @search_terms = params[:search].split(/\W+/).map {|x| x.downcase}
  # words to ignore
  @ignore = params[:exclude].split(/\W+/).map {|x| x.downcase}
  # include common words?
  params[:include]=='true' ? ignore_list = [] : ignore_list = ['', ' ', 'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have', 'i', 'it', 'for', 'not', 'on', 'with', 'he', 'as', 'you', 'do', 'at', 'this', 'but', 'his', 'by', 'from', 'they', 'we', 'say', 'her', 'she', 'or', 'an', 'will', 'my', 'one', 'all', 'would', 'there', 'their', 'what', 'so', 'up', 'out', 'if', 'about', 'who', 'get', 'which', 'go', 'me', 'when', 'make', 'can', 'time', 'just', 'him', 'know', 'take', 'person', 'into', 'year', 'your', 'good', 'some', 'could', 'them', 'see', 'other', 'than', 'then', 'now', 'look', 'only', 'come', 'its', 'over', 'think', 'also', 'back', 'after', 'use', 'two', 'how', 'our', 'work', 'first', 'well', 'way', 'even', 'new', 'want', 'because', 'any', 'these', 'give', 'day', 'most', 'us', 'is', 'had', 'am', 'are', 'were', 'oh', 't', 'd', 'ca', 'don', 'did']

  # emotion codes
  @emotion_index = 0
  happy_words = ['like', 'love', 'happy', 'excited', 'wonderful', 'fun', 'yes', 'always', 'favorite', 'enjoy', 'enjoyed', 'beautiful', 'cool']
  sad_words = ['pissed', 'angry', 'hate', 'dislike','mad', 'furious', 'bored', 'no', 'never', 'dumb', 'stupid', 'disappointing', 'disappointed', 'bitch']

  @request = "https://graph.facebook.com/#{@post_id}/comments?access_token=#{session[:access_token]}&limit=1000"
  puts @request
  @json = JSON.parse HTTParty.get(@request).response.body
  @words = {}
  # while there is data
  until @json['data'].empty?
    @json['data'].each do | comment |
      words = comment['message'].split(/\W+/).map {|x| x.downcase}
      words.each do |word|
        @emotion_index-=1 if sad_words.include? word
        @emotion_index+=1 if happy_words.include? word

        if @search_terms.empty?
          unless @ignore.include? word or ignore_list.include? word
            @words.has_key?(word) ?  @words[word] = @words[word]+1 : @words[word] = 1
          end
        else
          if @search_terms.include? word
            @words.has_key?(word) ?  @words[word] = @words[word]+1 : @words[word] = 1
          end
        end
      end
    end
    # follow the paging link
    @request = @json['paging']['next']
    @json = JSON.parse HTTParty.get(@request).response.body
  end
  @words = @words.to_a.sort_by! {|k,v| v}.reverse
  @e_class, @emotion = eval_emotion(@emotion_index)
  haml :success
end

get '/logout' do
  session.delete(:user)
  redirect '/'
end

# asset rules
get '/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

helpers do
  def eval_emotion index
    if index >= 10
      return 'green', 'EXCITED'
    elsif (0..10).include? index
      return 'yellow', 'HAPPY'
    elsif (-10..0).include? index
      return 'orange', 'BORED'
    elsif index < -10
      return 'red', 'ANGRY'
    end
  end
end
