#
## connection to the database
def connect()
  if ENV['DATABASE_URL'] != nil
    parts = ENV['DATABASE_URL'].split(/\/|:|@/)
    conn = PGconn.open(:host =>  parts[5], :dbname => parts[7], :user=> parts[3], :password=> parts[4])
  end
end
