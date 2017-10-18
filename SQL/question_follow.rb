require 'sqlite3'
require_relative 'template'
require_relative 'question'
require_relative 'reply'
require_relative 'user'
require_relative 'question_like'

class QuestionFollow

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_follows")
    data.map { |datum| QuestionFollow.new(datum) }
  end

  def initialize(options)
    @question_id = options['question_id']
    @user_id = options['user_id']
  end

  def self.followers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        users
      JOIN
        question_follows ON (question_follows.user_id = users.id)
      WHERE
        question_follows.question_id = ?
    SQL
    users.map { |user| User.new(user) }
  end

  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        questions
      JOIN
        question_follows ON (question_follows.question_id = questions.id)
      WHERE
        question_follows.user_id = ?
    SQL
    questions.map { |question| Question.new(question) }
  end

  def self.most_followed_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        questions
      JOIN
        question_follows ON (question_follows.question_id = questions.id)
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
