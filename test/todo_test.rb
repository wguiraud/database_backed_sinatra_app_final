# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/test'
require 'pry'
require 'mocha/minitest'

ENV['RACK_ENV'] = 'test'

require_relative '../todo'
require_relative '../database_persistence'

class TodoTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    @db = DatabasePersistence.new
    @logger = ENV['RACK_LOGGER']
  end

  def teardown
    @db.delete_all_lists_from_database
    @db.reset_sequence
    @db.disconnect
  end

  def creating_a_new_valid_list
    post '/lists', { list_name: 'groceries' }
    assert_equal 302, last_response.status
    get last_response['location']
    assert_equal 200, last_response.status
  end

  def creating_a_new_todo
    creating_a_new_valid_list
    post '/lists/1/todos', { todo: 'red wine' }
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal 200, last_response.status

    assert_includes last_response.body, 'The todo was added.'
    assert_includes last_response.body, 'red wine'
  end

  def test_home_page
    get '/'
    assert_equal 302, last_response.status

    # get last_response['location'] #testing with follow_redirect! method
    follow_redirect!
    assert_equal 200, last_response.status
  end

  def test_creating_list_with_invalid_names
    post '/lists', { list_name: '' }

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'List name must be between 1 and 100 characters.'

    post '/lists', { list_name: 'groceries' }
    post '/lists', { list_name: 'groceries' }

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'List name must be unique.'
  end

  def test_viewing_all_lists
    creating_a_new_valid_list
    get '/lists'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'groceries'
  end

  def test_creating_a_new_valid_list
    creating_a_new_valid_list
    assert_includes last_response.body, 'The list has been created.'
  end

  def test_removing_a_list
    post '/lists', { list_name: 'groceries' }

    post '/lists/1/destroy'
    assert_equal 302, last_response.status

    follow_redirect!
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'The list has been deleted.'
  end

  def test_updating_a_list_name
    creating_a_new_valid_list

    post '/lists/1', { list_name: 'wines' }
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal 200, last_response.status

    assert_includes last_response.body, 'The list has been updated.'
    assert_includes last_response.body, 'wines'
  end

  def test_adding_a_todo_to_a_list
    creating_a_new_todo

    post '/lists/1/todos', { todo: 'red wine' }
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal 200, last_response.status

    assert_includes last_response.body, 'The todo was added.'
    assert_includes last_response.body, 'red wine'
  end

  def test_removing_todo_from_list
    creating_a_new_valid_list

    post '/lists/1/todos/1/destroy'
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal 200, last_response.status

    assert_includes last_response.body, 'The todo has been deleted.'
  end

  def test_updating_todo_status
    creating_a_new_todo

    post '/lists/1/todos/1', { completed: true }
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal 200, last_response.status

    assert_includes last_response.body, 'The todo has been updated'
  end

  def test_mark_list_todos_as_completed
    post '/lists', { list_name: 'groceries' }
    post '/lists/1/todos', { todo: 'red wine' }
    post '/lists/1/todos', { todo: 'white wine' }

    post 'lists/1/complete_all'
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal 200, last_response.status

    assert_includes last_response.body, 'All todos have been completed.'
  end

  def test_lists_page_performs_single_query #instead of four N+1 queries
    query_count = 0

    # Mock the logger to count SQL queries
    mock_logger = Object.new
    def mock_logger.info(message)
      @count ||= 0
      @count += 1 if message.include?("Executing query:")
    end

    def mock_logger.count
      @count || 0
    end

    # Replace the normal logger with our mock
    # original_logger = DatabasePersistence.logger
    # DatabasePersistence.logger = mock_logger
    original_logger = @db.logger
    @db.logger = mock_logger

    #execute the method we want to optimize
    @db.all_lists

    #Get query count
    query_count = mock_logger.count

    #reset logger
    @db.logger = original_logger

    # Assert we only performed a single query
    assert_equal 1, mock_logger.count, "Expected 1 query but found #{query_count}"

  end
end
