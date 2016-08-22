require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require 'pry'

# setting up a configuration
# that enables sintras session capabilities
configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = session[:lists]

  erb :lists
end

get "/lists/new" do
  session[:lists] << { name: "new list", todos: [] }
  redirect "/lists"
end