#
## an index of all the animals
get '/animals' do
  # connect to the database
  conn = connect()

  # fetch the animals and pack them
  output = []
  result = conn.exec("select identifier, name from animals order by name")
  result.each do |row|
    output.push({
      id: row['identifier'],
      name: row['name'],
      link: '/animals/animal/' + row['identifier']
    })
  end
  conn.close()

  # return the output
  response.headers['Content-Type'] = 'application/json'
  JSON.generate(output)
end


#
## displays info for the animal of the day
get '/animals/aotd' do
  # connect to the database
  conn = connect()

  # fetch the animal of the day from the database
  result = conn.exec("select * from animals")
  count = result.count
  now = Time.now
  index = ((now.wday + 1) * now.yday) % count
  row = result[index]
  output = {
    id: row['identifier'],
    name: row['name'],
    photo: row['photo'],
    link: '/animals/animal/' + row['identifier']
  }
  conn.close()

  # return the output
  response.headers['Content-Type'] = 'application/json'
  JSON.generate(output)
end


#
## displays detailed info for an animal
get '/animals/animal/:id' do
  # initialize variables
  output = {}
  error = false

  # read the parameter
  id = params[:id]

  # connect to the database
  conn = connect()

  # try to fetch the animal from the database
  result = conn.exec("select * from animals where identifier = '" + id + "'")
  error = true if result.count != 1

  # pack the data in a hash
  if !error
    animal = result[0]
    output = {
      id: animal['identifier'],
      name: animal['name'],
      area: animal['area'],
      habitat: animal['habitat'],
      food: animal['food'].gsub("_1Q", "'"),
      size: animal['size'].gsub("_1Q", "'"),
      babies: animal['babies'],
      fact: animal['fact'],
      text: animal['text'].gsub('<br/>', '\n').gsub("_1Q", "'"),
      photo: animal['photo'],
      module: animal['module']
    }
  end
  conn.close()

  # return the output
  output = {
    message: "Non existent animal!",
    link: "/animals"
  } if error
  response.headers['Content-Type'] = 'application/json'
  JSON.generate(output)
end
