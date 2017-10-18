require 'sqlite3'
require 'singleton'
# require 'rubygems'
# require 'active_support/inflector'
require 'linguistics'

Linguistics.use :en

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class ModelBase

  def self.all
    class_name = self.to_s.downcase.en.plural
    data = QuestionsDatabase.instance.execute("SELECT * FROM #{class_name}")
    data.map { |datum| self.new(datum) }
  end

  def initialize
  end

  def self.find_by_id(id)
    class_name = self.to_s.downcase.en.plural
    result = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{class_name}
      WHERE
        id = ?
    SQL
    return nil unless result.length > 0
    self.new(result.first)
  end

  def self.where(params)
      class_name = self.to_s.downcase.en.plural
      if params.is_a?(Hash)
        where_line = params.keys.map { |key| "#{key} = ?" }.join(" AND ")
        vals = params.values
      else
        where_line = params
        vals = []
      end

      data = QuestionsDatabase.instance.execute(<<-SQL, *vals)
        SELECT
          *
        FROM
          #{class_name}
        WHERE
          #{where_line}
      SQL

      data.map { |datum| self.new(datum) }
  end


end
