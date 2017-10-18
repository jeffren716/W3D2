require 'sqlite3'
require_relative 'template'
require_relative 'question'
require_relative 'reply'
require_relative 'question_follow'
require_relative 'question_like'

class User < ModelBase
  attr_accessor :fname, :lname

  # def self.all
  #   data = QuestionsDatabase.instance.execute("SELECT * FROM users")
  #   data.map { |datum| User.new(datum) }
  # end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  # def self.find_by_id(id)
  #   user = QuestionsDatabase.instance.execute(<<-SQL, id)
  #     SELECT
  #       *
  #     FROM
  #       users
  #     WHERE
  #       id = ?
  #   SQL
  #   return nil unless user.length > 0
  #   User.new(user.first)
  # end

  def self.find_by_name(fname, lname)
    users = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        fname, lname
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL

    users.map { |user| User.new(user) }
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def questions_asked
    questions = Question.find_by_author_id(@id)
    questions.nil? ? 0 : questions.count
  end

  def total_likes
    likes = QuestionLike.total_likes_for_user_id(@id)
    likes.nil? ? 0 : likes
  end

  def average_karma
    p total_likes
    p questions_asked
    total_likes / questions_asked
  end

  def save
    if !@id.nil?
      update
    else
      QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
        INSERT INTO
          users (fname, lname)
        VALUES
          (?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    end
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
      UPDATE
        users
      SET
        fname = ?, lname = ?
      WHERE
        id = ?
    SQL
  end
end
