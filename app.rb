require 'sinatra'
require 'pg'
require 'securerandom'
require 'json'
require_relative 'rb/misc.rb'

require_relative 'rb/accounts.rb'
require_relative 'rb/modules.rb'
require_relative 'rb/animals.rb'
require_relative 'rb/quizzes.rb'

get '/' do
  File.read("root.html")
end
