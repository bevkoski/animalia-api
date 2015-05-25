#
## lists all the available quizzes
get '/quizzes' do
  # connect to the database
  conn = connect()

  # fetch the modules from the database and pack them
  output = []
  result = conn.exec("select * from modules")
  ctr = 1
  result.each do |row|
    data = {
      number: row['num'].to_i,
      module: row['module'],
      link: '/quizzes/quiz/' + row['module']
    }
    output.push(data)
    ctr += 1
  end
  data = {
    number: ctr,
    module: 'Expert',
    link: '/quizzes/quiz/Expert'
  }
  output.push(data)
  conn.close()

  # return the output
  response.headers['Content-Type'] = 'application/json'
  JSON.generate(output)
end


#
## lists all the available questions
get '/quizzes/questions' do
  # connect to the database
  conn = connect()

  # fetch the questions and pack them
  output = []
  result = conn.exec("select * from questions order by id")
  result.each do |row|
    output.push({
      id: row['id'].to_i,
      question: row['question'],
      answer: row['correct'],
      options: [row['correct'], row['wrong1'], row['wrong2'], row['wrong3']],
      module: row['module']
    })
  end
  conn.close()

  # return the output
  response.headers['Content-Type'] = 'application/json'
  JSON.generate(output)
end


#
## generates a quiz with 5 random questions from the given module
get '/quizzes/quiz/:quiz' do
  # initialize variables
  output = []
  error = false

  # read the parameter
  quiz = params[:quiz]

  # connect to the database
  conn = connect()

  # check for an error and create the subquery
  result = conn.exec("select module from modules")
  modules = []
  result.each { |row| modules.push(row['module']) }
  subquery = "select * from questions"
  if modules.include? quiz
    subquery += " where module = '" + quiz + "'"
  elsif quiz != 'Expert'
    error = true
  end

  # fetch 5 random questions and pack the quiz
  if !error
    result = conn.exec("select * from (#{subquery}) as subquery order by random() limit 5")
    ctr = 1
    result.each do |row|
      options = [row['correct'], row['wrong1'], row['wrong2'], row['wrong3']].shuffle
      answer = options.index(row['correct']) + 1
      output.push({
        number: ctr,
        question: row['question'],
        options: {
          1 => options[0],
          2 => options[1],
          3 => options[2],
          4 => options[3]
        },
        answer: answer
      })
      ctr += 1
    end
  end
  conn.close()

  # return the output
  output = {
    message: "Non existent quiz type!",
    link: "/quizzes"
  } if error
  response.headers['Content-Type'] = 'application/json'
  JSON.generate(output)
end


#
## submits the results for a given quiz
get '/quizzes/submit' do
  # initialize variables
  output = {}
  error = false

  # read the parameters
  username = params[:username]
  type = params[:type]
  guesses = params[:guesses]
  timeleft = params[:timeleft]
  if username.nil? || type.nil? || guesses.nil? || timeleft.nil?
    output, error = { message: "Parameters are missing!" }, true
  end

  # connect to the database
  conn = connect()

  # try to fetch the user from the database
  if !error
    result = conn.exec("select * from users where username = '" + username + "'")
    output, error = { message: "Non existent username!" }, true if result.count != 1
  end

  # calculate the score and insert the score into the highscores table
  if !error
    score = (guesses.to_i * 1075 + timeleft.to_i * 15) * 2
    stars = 1
    if guesses.to_i == 5
      stars = 3
    elsif guesses.to_i > 2
      stars = 2
    end
    conn.exec("insert into highscores(username,score,type) values('#{username}','#{score}','#{type}')")
    output = {
      message: "Congratulations!",
      score: score,
      stars: stars,
      highscores: '/quizzes/highscores/' + type
    }
  end
  conn.close()

  # return the output
  response.headers['Content-Type'] = 'application/json'
  JSON.generate(output)
end


#
## displays the high score lists
get '/quizzes/highscores/:list' do
  # initialize variables
  output = []

  # read the parameter
  list = params[:list]

  # connect to the database
  conn = connect()

  # try to fetch the list from the database
  query = "select u.name, u.surname, h.score, h.type from (
  select * from users where name != 'none' and surname != 'none') as u,
  highscores as h where u.username = h.username"
  if list == 'Total'
    query +=  " order by h.score desc"
  else
    query += " and h.type = '#{list}' order by h.score desc"
  end
  result = conn.exec(query)
  if result.count > 0
    ctr = 1
    result.each do |row|
      entry = {
          place: ctr,
          user: "#{row['name']} #{row['surname']}",
          score: row['score']
      }
      entry[:type] = row['type'] if list = 'Total'
      ctr += 1
      output.push(entry)
    end
  else
    output = { message: "No entries for that quiz type." }
  end
  conn.close()

  # return the output
  response.headers['Content-Type'] = 'application/json'
  JSON.generate(output)
end
