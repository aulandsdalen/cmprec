# populate database w/ contents of CSV data files
require 'csv'
require 'sequel'

FILE_SERVER_DATA = "server.csv"
FILE_RLAB_DATA = "rlab.csv"

print "postgres user? "
dbuser = gets.chomp
print "postgres password? "
dbpassword = gets.chomp 
print "postgres database? "
dbname = gets.chomp

DB = Sequel.connect("postgres://#{dbuser}:#{dbpassword}@localhost/#{dbname}")

def get_true_data(str)
	md5hash = str.pop
	filesize = str.pop
	truefname = str.join(",")
	[truefname, filesize, md5hash]
end

CSV.foreach(FILE_SERVER_DATA) do |row|
	get_true_data(row)
end