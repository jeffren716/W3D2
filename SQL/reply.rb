require 'sqlite3'
require_relative 'template'
require_relative 'question'
require_relative 'user'
require_relative 'question_follow'
require_relative 'question_like'

class Reply < ModelBase

  attr_accessor :parent_id, :question_id, :user_id, :body

  # def self.all
  #   data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
  #   data.map { |datum| Reply.new(datum) }
  # end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent_id = options['parent_id']
    @user_id = options['user_id']
    @body = options['body']
  end

  # def self.find_by_id(id)
  #   reply = QuestionsDatabase.instance.execute(<<-SQL, id)
  #     SELECT
  #       *
  #     FROM
  #       replies
  #     WHERE
  #       id = ?
  #   SQL
  #   return nil unless reply.length > 0
  #   Reply.new(reply.first)
  # end

  def self.find_by_user_id(user_id)
    user_replies = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?
    SQL
    return nil unless user_replies.length > 0
    user_replies.map { |reply| Reply.new(reply) }
  end

  def self.find_by_question_id(question_id)
    thread = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL
    return nil unless thread.length > 0
    thread.map { |reply| Reply.new(reply) }
  end

  def author
    User.find_by_id(@user_id)
  end

  def question
    Question.find_by_id(@question_id)
  end

  def parent_reply
    Reply.find_by_id(@parent_id)
  end

  def child_replies
    Reply.all.select { |reply| @id == reply.parent_id }
  end

  def save
    if @id
      update
    else
      QuestionsDatabase.instance.execute(<<-SQL, @question_id, @parent_id, @user_id, @body)
        INSERT INTO
          replies (question_id, parent_id, user_id, body)
        VALUES
          (?, ?, ?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    end
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @question_id, @parent_id, @user_id, @body, @id)
      UPDATE
        replies
      SET
        question_id = ?, parent_id = ?, user_id = ?, body = ?
      WHERE
        id = ?
    SQL
  end
end
