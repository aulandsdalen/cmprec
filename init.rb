require 'sequel'

print "postgres user? "
dbuser = gets.chomp
print "postgres password? "
dbpassword = gets.chomp 
print "postgres database? "
dbname = gets.chomp

DB = Sequel.connect("postgres://#{dbuser}:#{dbpassword}@localhost:5432/#{dbname}")

DB.create_table :remotefiles do
	primary_key :id
	String :name
	Bigint :size
	String :md5
end

DB.create_table :recoveredfiles do
	primary_key :id
	String :name
	Bigint :size
	String :md5
end