require 'sqlite3'
require_relative 'template'
require_relative 'question'
require_relative 'reply'
require_relative 'question_follow'
require_relative 'user'

class QuestionLike

  attr_reader :likes

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_likes")
    data.map { |datum| QuestionLike.new(datum) }
  end

  def initialize(options)
    @likes = options['likes']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end

  def self.likers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        users
      JOIN
        question_likes ON (question_likes.user_id = users.id)
      WHERE
        question_likes.question_id = ?
    SQL
    users.map { |user| User.new(user) }
  end

  def self.num_likes_for_question_id(question_id)
    likes = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        COUNT(likes) AS num_likes
      FROM
        question_likes
      WHERE
        question_likes.question_id = ?

    SQL
    likes.first['num_likes']
  end

  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        questions
      JOIN
        question_likes ON (question_likes.question_id = questions.id)
      WHERE
        question_likes.user_id = ?
    SQL
    questions.map { |question| Question.new(question) }
  end

  def self.total_likes_for_user_id(user_id)
    likes = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        SUM(likes) as total_likes
      FROM
        question_likes
      JOIN
        questions ON question_likes.question_id = questions.id
      WHERE
        questions.author_id = ?
    SQL
    likes.first['total_likes']
  end

  def self.most_liked_question(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        questions
      JOIN
        question_likes ON (question_likes.question_id = questions.id)
      GROUP BY
        question_id
      ORDER BY
        COUNT(*) DESC, question_id DESC
    SQL
    return nil unless questions.length > 0
    questions.map! { |question| Question.new(question) }
    questions.take(n)
  end

end
