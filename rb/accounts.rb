#
## creates a generic account for a new user
get '/accounts/start' do
  # connect to the database
  conn = connect()

  # create a random username and check its validity
  username = "usr" + SecureRandom.hex
  result = conn.exec("select * from users where username = '" + username + "'")
  while result.count != 0
    username = "usr" + SecureRandom.hex
    result = conn.exec("select * from users where username = '" + username + "'")
  end

  # store the random username into the database
  conn.exec("insert into users(username) values('" + username + "')")
  conn.close()

  # return the output
  output = { message: "User created!", username: username }
  response.headers['Content-Type'] = 'application/json'
  JSON.generate(output)
end


#
## updates an account with info provided by facebook
get '/accounts/update' do
  # initialize variables
  output = { message: "Account succesfuly updated!" }
  error = false

  # read the parameters
  username = params[:username]
  name = params[:name]
  surname = params[:surname]
  email = params[:email]
  if username.nil? || name.nil? || surname.nil? || email.nil?
    output, error = { message: "Parameters are missing!" }, true
  end

  # connect to the database
  conn = connect()

  # try to fetch the user from the database
  if !error
    result = conn.exec("select * from users where username = '" + username + "'")
    output, error = { message: "Non existent username!" }, true if result.count != 1
  end

  # update the account with the given username
  conn.exec("update users set name = '#{name}', surname = '#{surname}',
  email = '#{email}' where username = '#{username}'") if !error
  conn.close()

  # return the output
  response.headers['Content-Type'] = 'application/json'
  JSON.generate(output)
end


#
## displays detailed info for a given user
get '/accounts/account/:username' do
  # initialize variables
  output = {}
  error = false

  # read the parameter
  username = params[:username]

  # connect to the database
  conn = connect()

  # try to fetch the user from the database
  result = conn.exec("select * from users where username = '" + username + "'")
  output, error = { message: "Non existent username!" }, true if result.count != 1

  # pack the info in a hash
  if !error
    output = {
      user: "#{result[0]['name']} #{result[0]['surname']}",
      email: result[0]['email'],
      highscore: 0,
      ranking: {
        Arthropods: "none",
        Amphibians: "none",
        Reptiles: "none",
        Birds: "none",
        Mammals: "none",
        Expert: "none",
        Total: "none"
      }
    }
    result = conn.exec("select score from highscores where username = '#{username}' order by score desc")
    output[:highscore] = result[0]['score'].to_i if result.count > 0
    result = conn.exec("select distinct type from highscores")
    result.each do |type|
      subresult = conn.exec("select * from highscores where type = '#{type['type']}' order by score desc")
      ctr = 1
      subresult.each do |row|
        if row['username'] == username
          output[:ranking][type['type'].to_sym] = ctr
          break
        end
        ctr += 1
      end
    end
    result = conn.exec("select * from highscores order by score desc")
    ctr = 1
    result.each do |row|
      if row['username'] == username
        output[:ranking][:Total] = ctr
        break
      end
      ctr += 1
    end
  end
  conn.close()

  # return the output
  response.headers['Content-Type'] = 'application/json'
  JSON.generate(output)
end
