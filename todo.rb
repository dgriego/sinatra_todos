require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'sinatra/content_for'

def error_for_list_name(name)
  if !(1..100).cover? name.size
    'List name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    'List name must be unique.'
  end
end

def error_for_todo_text(text)
  if !(1..100).cover? text.size
    'Todo must be between 1 and 100 characters.'
  end
end

# setting up a configuration
# that enables sintras session capabilities
configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

get '/lists' do
  @lists = session[:lists]

  erb :lists
end

get '/lists/new' do
  erb :new_list
end

# Edit A List'
get '/lists/:id' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  erb :edit
end

# Edit A Todo Lists info
get '/lists/:id/edit' do
  @id = params[:id].to_i
  @list = session[:lists][@id]

  erb :edit_list
end

# Edit a Todo List
post '/lists/:id' do
  list_name = params[:list_name].strip
  @id = params[:id].to_i
  @list = session[:lists][@id]

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list
  else
    @list[:name] = list_name
    session[:success] = 'The list has been updated.'
    redirect "/lists/#{@id}"
  end
end

# Create a New Todo List
post '/lists' do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# Create a New Todo for a List
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip

  error = error_for_todo_text(text)
  if error
    session[:error] = error

    erb :edit
  else
    @list[:todos] << { name: text, completed: false }
    session[:success] = 'The todo was added.'

    redirect "/lists/#{@list_id}"
  end
end

# Delete a Todo List
post '/lists/:id/destroy' do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = 'The list has been deleted.'

  redirect '/lists'
end

# Delete a Todo Item
post '/lists/:list_id/todo/:todo_id/destroy' do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  session[:lists][list_id][:todos].delete_at(todo_id)
  session[:success] = 'The todo has been deleted.'

  redirect "/lists/#{list_id}"
end

# Update status on a Todo item
post '/lists/:list_id/todo/:todo_id' do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  list = session[:lists][list_id][:todos][todo_id]
  list[:completed] = true

  redirect "/lists/#{list_id}"
end
