require 'csv'
require 'sequel'
require 'rdispatch'

print "postgres user? "
dbuser = gets.chomp
print "postgres password? "
dbpassword = gets.chomp 
print "postgres database? "
dbname = gets.chomp

DB = Sequel.connect("postgres://#{dbuser}:#{dbpassword}@localhost:5432/#{dbname}")

remotefiles = DB[:remotefiles]
recoveredfiles = DB[:recoveredfiles]

remotefiles_arr = remotefiles.all
recoveredfiles_arr = recoveredfiles.all

rd = RDispatch.new