require 'sqlite3'
require_relative 'template'
require_relative 'user'
require_relative 'reply'
require_relative 'question_follow'
require_relative 'question_like'

class Question < ModelBase

  attr_accessor :title, :body, :author_id

  # def self.all
  #   data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
  #   data.map { |datum| Question.new(datum) }
  # end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  # def self.find_by_id(id)
  #   question = QuestionsDatabase.instance.execute(<<-SQL, id)
  #     SELECT
  #       *
  #     FROM
  #       questions
  #     WHERE
  #       id = ?
  #   SQL
  #   return nil unless question.length > 0
  #   Question.new(question.first)
  # end

  def author
    User.find_by_id(@author_id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def followers
    QuestionFollow.followers_for_question_id(@id)
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_question(n)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  def self.find_by_author_id(author_id)
    author_questions = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL
    return nil unless author_questions.length > 0
    author_questions.map { |question| Question.new(question)}
  end

  def save
    if !@id.nil?
      update
    else
      QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id)
        INSERT INTO
          questions (title, body, author_id)
        VALUES
          (?, ?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    end
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id, @id)
      UPDATE
        questions
      SET
        title = ?, body = ?, author_id = ?
      WHERE
        id = ?
    SQL
  end

end
