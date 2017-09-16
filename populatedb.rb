# populate database w/ contents of CSV data files
=begin
	primary_key :id
	String :name
	Bigint :size
	String :md5
=end
require 'csv'
require 'sequel'

def get_true_data(str)
	md5hash = str.pop
	filesize = str.pop
	truefname = str.join(",")
	[truefname, filesize, md5hash]
end

FILE_SERVER_DATA = "server.csv"
FILE_RLAB_DATA = "rlab.csv"

print "postgres user? "
dbuser = gets.chomp
print "postgres password? "
dbpassword = gets.chomp 
print "postgres database? "
dbname = gets.chomp

DB = Sequel.connect("postgres://#{dbuser}:#{dbpassword}@localhost:5432/#{dbname}")

remotefiles = DB[:remotefiles]
recoveredfiles = DB[:recoveredfiles]

#CSV.foreach(FILE_SERVER_DATA) do |row|
#	get_true_data(row)
#end

CSV.foreach(FILE_RLAB_DATA) do |row|
	md5hash = row.pop
	filesize = row.pop
	filename = row.join(",")
	recoveredfiles.insert(:name => filename, :size => filesize, :md5 => md5hash)
end