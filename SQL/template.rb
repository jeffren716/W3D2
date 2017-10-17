require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
  attr_accessor :fname, :lname

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM users")
    data.map { |datum| User.new(datum) }
  end

  def self.find_by_id(id)
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    return nil unless user.length > 0
    User.new(user.first)
  end

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

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def create
    raise "#{self} already in database" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
      INSERT INTO
        users (fname, lname)
      VALUES
        (?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
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

class Question

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    data.map { |datum| Question.new(datum) }
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    return nil unless question.length > 0
    Question.new(question.first)
  end

  def author
    User.find_by_id(@author)
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

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author = options['author']
  end
end

class Reply

  attr_accessor :parent, :id

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
    data.map { |datum| Reply.new(datum) }
  end

  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    return nil unless reply.length > 0
    Reply.new(reply.first)
  end

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
    Reply.find_by_id(@parent)
  end

  def child_replies
    Reply.all.select { |reply| @id == reply.parent }
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent = options['parent']
    @user_id = options['user_id']
    @body = options['body']
  end
end

class QuestionFollow

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_follows")
    data.map { |datum| QuestionFollow.new(datum) }
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

  def initialize(options)
    @question_id = options['question_id']
    @user_id = options['user_id']
  end

end

class QuestionLike

  attr_reader :likes

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_likes")
    data.map { |datum| QuestionLike.new(datum) }
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

  def initialize(options)
    @likes = options['likes']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end
end
# class Playwright
#   attr_accessor :name, :birth_year
#   attr_reader :id
#
#   def self.all
#     data = QuestionsDatabase.instance.execute("SELECT * FROM playwrights")
#     data.map { |datum| Playwright.new(datum) }
#   end
#
#   def self.find_by_name(name)
#     person = QuestionsDatabase.instance.execute(<<-SQL, name)
#       SELECT
#         *
#       FROM
#         playwrights
#       WHERE
#         name = ?
#     SQL
#     return nil unless person.length > 0 # person is stored in an array!
#
#     Playwright.new(person.first)
#   end
#
#   def initialize(options)
#     @id = options['id']
#     @name = options['name']
#     @birth_year = options['birth_year']
#   end
#
#   def create
#     raise "#{self} already in database" if @id
#     QuestionsDatabase.instance.execute(<<-SQL, @name, @birth_year)
#       INSERT INTO
#         playwrights (name, birth_year)
#       VALUES
#         (?, ?)
#     SQL
#     @id = QuestionsDatabase.instance.last_insert_row_id
#   end
#
#   def update
#     raise "#{self} not in database" unless @id
#     QuestionsDatabase.instance.execute(<<-SQL, @name, @birth_year, @id)
#       UPDATE
#         playwrights
#       SET
#         name = ?, birth_year = ?
#       WHERE
#         id = ?
#     SQL
#   end
#
#   def get_plays
#     raise "#{self} not in database" unless @id
#     plays = QuestionsDatabase.instance.execute(<<-SQL, @id)
#       SELECT
#         *
#       FROM
#         plays
#       WHERE
#         playwright_id = ?
#     SQL
#     plays.map { |play| Play.new(play) }
#   end
#
# end
# © 2017 GitHub, Inc.
# Terms
# Privacy
# Security
# Status
# Help
# Contact GitHub
# API
# Training
# Shop
# Blog
# About
