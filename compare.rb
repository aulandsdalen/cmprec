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

# rd = RDispatch.new
recoveredfiles_arr.each do |file|
	remote_sibling = remotefiles.where(:name => file[:name])
	unless remote_sibling.nil?
		if (remote_sibling[:md5] == file[:md5])
			puts "#{remote_sibling[:name]} = #{file[:name]}"
		else
			puts "different hash for #{remote_sibling[:name]}"
		end
	else
		puts "#{file[:name]} was not found on server"
	end
end