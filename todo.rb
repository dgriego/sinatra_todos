require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'sinatra/content_for'

# setting up a configuration
# that enables sintras session capabilities
configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

helpers do
  def list_complete?(list)
    todos_count(list) > 0 && todos_remaining_count(list) == 0
  end

  def todos_count(list)
    list[:todos].size
  end

  def list_class(list)
    'complete' if list_complete?(list)
  end

  def todos_remaining_count(list)
    list[:todos].select { |todo| !todo[:completed] }.size
  end

  def list_count(list)
    list[:todos].size
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition do |list|
      list_complete?(list)
    end

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition do |todo|
      todo[:completed]
    end

    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }
  end

  def load_list(index)
    list = session[:lists][index] if index
    return list if list

    session[:error] = "The specified list was not found."
    redirect "/lists"
  end
end

before do
  session[:lists] ||= []
end

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
  @list = load_list(@list_id)

  erb :edit
end

# Edit A Todo Lists info
get '/lists/:id/edit' do
  @id = params[:id].to_i
  @list = load_list(@id)

  erb :edit_list
end

# Edit a Todo List
post '/lists/:id' do
  list_name = params[:list_name].strip
  @id = params[:id].to_i
  @list = load_list(@id)

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
  @list = load_list(@list_id)
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
  @list = load_list(list_id)

  is_completed = params[:completed] == 'true'
  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = 'The todo has been updated.'

  redirect "/lists/#{list_id}"
end

post '/lists/:id/complete_all' do
  list_id = params[:id].to_i
  @list = load_list(list_id)

  @list[:todos].each_with_index do |todo|
    todo[:completed] = true
  end
  session[:success] = 'All todos have been completed.'

  redirect "/lists/#{list_id}"
end
