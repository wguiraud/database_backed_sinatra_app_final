# frozen_string_literal: true

require 'pg'

# class implementing the inteface between the sinatra todo
# application and the interaction with the
class DatabasePersistence
  def initialize(logger: nil)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          elsif ENV['RACK_ENV'] == 'test'
            PG.connect(dbname: 'test_todos')
          else
            PG.connect(dbname: 'todos')
          end
    @logger = logger
  rescue PG::Error => e
    puts "Database connection error: #{e.message}"
    @logger&.error("Database connection error: #{e.message}")
    raise
  end

  def find_list(id)
    list_table_name = @db.quote_ident('lists')
    sql = <<-SQL
    SELECT * FROM #{list_table_name}
    WHERE id = $1;
    SQL

    result = query(sql, id)
    tuple = result.first
    list_id = tuple['id'].to_i
    todos = find_todos_for_list(list_id)

    { id: list_id, name: tuple['name'], todos: todos }
  end

  def all_lists
    table_name = @db.quote_ident('lists')
    #sql = "SELECT * FROM #{table_name}"
    sql = <<~SQL
      SELECT lists.*,
          COUNT(todos.completed) AS "number_of_todos",
          COUNT(NULLIF(todos.completed, true)) AS "remaining_number_of_todos"
      FROM #{table_name}
      LEFT JOIN todos ON todos.list_id = lists.id
      GROUP BY lists.id
      ORDER BY lists.name;
    SQL
    result = query(sql)

    result.map do |tuple|
      { id: tuple['id'].to_i,
        name: tuple['name'],
        number_of_todos: tuple['number_of_todos'].to_i,
        remaining_number_of_todos: tuple['remaining_number_of_todos'].to_i
      }
    end
  end

  def add_new_list(list_name)
    table_name = @db.quote_ident('lists')
    sql = "INSERT INTO #{table_name} (name) VALUES ($1);"
    query(sql, list_name)
  end

  def remove_list(list_id)
    table_name = @db.quote_ident('lists')
    sql = "DELETE FROM #{table_name} WHERE id = $1;"
    query(sql, list_id)
  end

  def update_list_name(list_id, list_name)
    table_name = @db.quote_ident('lists')
    sql = <<~SQL
      UPDATE #{table_name}
      SET name = $1
      WHERE id = $2;
    SQL
    query(sql, list_name, list_id) # argument order matters!!!
  end

  def add_new_todo(list_id, todo_name)
    table_name = @db.quote_ident('todos')
    sql = <<~SQL
      INSERT INTO #{table_name} (name, list_id)#{' '}
      VALUES ($1, $2);
    SQL
    query(sql, todo_name, list_id)
  end

  def remove_todo(list_id, todo_id)
    table_name = @db.quote_ident('todos')
    sql = <<~SQL
      DELETE FROM #{table_name}
      WHERE id = $1 AND list_id = $2;
    SQL
    query(sql, todo_id, list_id)
  end

  def update_todo(list_id, todo_id, status)
    table_name = @db.quote_ident('todos')
    sql = <<~SQL
      UPDATE #{table_name}#{'  '}
      SET completed = $1 WHERE id = $2 AND list_id = $3;
    SQL
    query(sql, status, todo_id, list_id)
  end

  def complete_all_todos(list_id)
    table_name = @db.quote_ident('todos')
    sql = <<~SQL
      UPDATE #{table_name}#{'  '}
      SET completed = true WHERE list_id = $1;
    SQL
    query(sql, list_id)
  end

  def disconnect
    @db.close
  end

  def delete_all_lists_from_database
    table_name = @db.quote_ident('lists')
    @db.exec("DELETE FROM #{table_name};")
  end

  def reset_sequence
    @db.exec('ALTER SEQUENCE lists_id_seq RESTART WITH 1')
  end

  # private

  def query(statement, *params)
    @logger.info("#{statement}: #{params}")
    @db.exec_params(statement, params)
  end

  def find_todos_for_list(list_id)
    table_name = @db.quote_ident('todos')
    query = "SELECT * FROM #{table_name} WHERE list_id = $1;"
    result = query(query, list_id)

    result.map do |todo_tuple|
      { id: todo_tuple['id'].to_i,
        name: todo_tuple['name'],
        completed: todo_tuple['completed'] == 't' }
    end
  end
end
