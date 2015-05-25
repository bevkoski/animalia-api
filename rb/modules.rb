#
## lists all the available modules
get '/modules' do
  # connect to the database
  conn = connect()

  # fetch the modules from the database
  output = []
  result = conn.exec("select * from modules")
  result.each do |row|
    data = {
      number: row['num'].to_i,
      module: row['module'],
      text: row['text'].gsub('<br/>', '\n').gsub("_1Q", "'"),
      icon: row['icon'],
      link: '/modules/' + row['module']
    }
    output.push(data)
  end
  conn.close()

  # return the output
  response.headers['Content-Type'] = 'application/json'
  JSON.generate(output)
end


#
## displays info for the selected module, including a spotlight animal and a list of all the animals
get '/modules/:module' do
  # initialize variables
  output = {}
  error = false

  # read the parameter
  mod = params[:module]

  # connect to the database
  conn = connect()

  # try to fetch the module from the database
  result = conn.exec("select * from modules where module = '" + mod + "'")
  error = true if result.count != 1

  # pack the data in a hash
  if !error
    # pack the module info
    output = {
      number: result[0]['num'].to_i,
      module: result[0]['module'],
      text: result[0]['text'],
      icon: result[0]['icon']
    }
    # fetch the animals
    result = conn.exec("select * from animals where module = '" + mod + "' order by name")
    # pack the spotlight animal
    count = result.count
    now = Time.now
    index = ((now.wday + 1) * now.yday) % count
    row = result[index]
    output[:spotlight] = {
      id: row['identifier'],
      name: row['name'],
      photo: row['photo'],
      fact: row['fact'],
      link: '/animals/animal/' + row['identifier']
    }
    # pack the animals
    animals = []
    result.each do |row|
      animals.push({
        id: row['identifier'],
        name: row['name'],
        link: '/animals/animal/' + row['identifier']
      })
    end
    output[:animals] = animals
  end
  conn.close()

  # return the output
  output = {
    message: "Non existent module!",
    modules: ["Amphibians", "Arthropods", "Birds", "Mammals", "Reptiles"]
  } if error
  response.headers['Content-Type'] = 'application/json'
  JSON.generate(output)
end

get '/modules/:module/animals' do
  # initialize variables
  output = []
  error = false

  # read the parameter
  mod = params[:module]

  # connect to the database
  conn = connect()

  # try to fetch the module from the database
  result = conn.exec("select * from modules where module = '" + mod + "'")
  error = true if result.count != 1

  # pack the data in a hash
  if !error
    # fetch the animals
    result = conn.exec("select * from animals where module = '" + mod + "' order by name")
    result.each do |row|
      output.push({
        id: row['identifier'],
        name: row['name'],
        link: '/animals/animal/' + row['identifier']
      })
    end
  end
  conn.close()

  # return the output
  output = {
    message: "Non existent module!",
    modules: ["Amphibians", "Arthropods", "Birds", "Mammals", "Reptiles"]
  } if error
  response.headers['Content-Type'] = 'application/json'
  JSON.generate(output)
end
