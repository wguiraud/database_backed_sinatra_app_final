# frozen_string_literal: true

# Class abstracting away the session data storage
class SessionPersistence
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def find_list(id)
    @session[:lists].find { |list| list[:id] == id }
  end

  def all_lists
    @session[:lists]
  end

  def add_new_list(list_name)
    id = next_element_id(@session[:lists])
    @session[:lists] << { id: id, name: list_name, todos: [] }
  end

  def remove_list(id)
    @session[:lists].reject! { |list| list[:id] == id }
  end

  def update_list_name(id, name)
    list = find_list(id)
    list[:name] = name
  end

  def add_new_todo(list_id, todo_name)
    list = find_list(list_id)
    id = next_element_id(list[:todos])
    list[:todos] << { id: id, name: todo_name, completed: false }
  end

  def remove_todo(list_id, todo_id)
    list = find_list(list_id)
    list[:todos].reject! { |todo| todo[:id] == todo_id }
  end

  def update_todo(list_id, todo_id, status)
    list = find_list(list_id)
    todo = list[:todos].find { |t| t[:id].to_i == todo_id }
    todo[:completed] = status
  end

  def complete_all_todos(list_id)
    list = find_list(list_id)
    list[:todos].each { |todo| todo[:completed] = true }
  end

  private

  def next_element_id(elements)
    max = elements.map { |todo| todo[:id] }.max || 0
    max + 1
  end
end
