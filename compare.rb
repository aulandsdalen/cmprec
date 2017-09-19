require 'csv'
require 'sequel'
require 'rdispatch'
require 'progress_bar'

print "postgres user? "
dbuser = gets.chomp
print "postgres password? "
dbpassword = gets.chomp 
print "postgres database? "
dbname = gets.chomp

DB = Sequel.connect("postgres://#{dbuser}:#{dbpassword}@localhost:5432/#{dbname}")

remotefiles = DB[:remotefiles]
recoveredfiles = DB[:recoveredfiles]

#remotefiles_arr = remotefiles.all
puts "Loading list of recoverd files..."
recoveredfiles_arr = recoveredfiles.all

cmpbar = ProgressBar.new(recoveredfiles_arr.length, :bar, :counter, :percentage, :elapsed,)

# rd = RDispatch.new
equal_files = []
unequal_files = []
notfound_files = []
logfile = []

recoveredfiles_arr.each do |file|
	cmpbar.increment!
	if file[:name].include?("@Syno")
		logfile << "#{file[:name]} is synology resource, skipping..."
	else
		remote_sibling = remotefiles.where(:name => file[:name]).first
		unless remote_sibling.nil?
			if (remote_sibling[:md5] == file[:md5])
				logfile << "#{remote_sibling[:name]} = #{file[:name]}"
				equal_files << "#{remote_sibling[:name]};#{remote_sibling[:size]};#{remote_sibling[:md5]}"
			else
				logfile << "different hash for #{remote_sibling[:name]}"
				unequal_files << "#{remote_sibling[:name]};#{remote_sibling[:size]};#{remote_sibling[:md5]};#{file[:name]};#{file[:size]};#{file[:md5]}"
			end
		else
			logfile << "#{file[:name]} was not found on server"
			notfound_files << "#{file[:name]};#{file[:size]};#{file[:md5]}"
		end
	end
end

open('equal_files_recoveredfiles.csv', 'a') {|f|
	equal_files.each do |record|
		f.puts record
	end
}

open('unequal_files_recoveredfiles.csv', 'a') {|f|
	unequal_files.each do |record|
		f.puts record
	end
}

open('notfound_files_recoveredfiles.csv', 'a') {|f|
	notfound_files.each do |record|
		f.puts record
	end
}

open('log_recoveredfiles.txt', 'a') {|f|
	logfile.each do |log|
		f.puts log
	end
}