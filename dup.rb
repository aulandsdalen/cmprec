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

equal_files = []
unequal_files = []
no_dup_files = []
log = []

puts "Loading list of files..."
files_array = remotefiles.all

dupbar = ProgressBar.new(files_array.length, :bar, :counter, :percentage, :elapsed,)

files_array.each do |file|
	fullname = file[:name]
	shortname = "%" + fullname.split("/").last
	similar_files = remotefiles.where(Sequel.like(:name, shortname)).all
	if similar_files.empty?
	#	log << "no duplicates for #{file[:name]}"
	#	no_dup_files << "#{file[:name]};#{file[:size]};#{file[:md5]}"
		File.write('log.txt', "no duplicates for #{file[:name]}\n", File.size("log.txt"), mode: 'a')
		File.write('nodup.csv', "#{file[:name]};#{file[:size]};#{file[:md5]}\n", File.size('nodup.csv'), mode: 'a')
	else
		similar_files.each do |sf|
			if sf[:md5] == file[:md5]
			#	log << "found duplicate for #{file[:name]}"
			#	equal_files << "#{sf[:name]};#{sf[:size]};#{sf[:md5]};#{file[:name]};#{file[:size]};#{file[:md5]}"
				File.write('log.txt', "found duplicate for #{file[:name]}\n", File.size("log.txt"), mode: 'a')
				File.write("dup.csv", "#{sf[:name]};#{sf[:size]};#{sf[:md5]};#{file[:name]};#{file[:size]};#{file[:md5]}\n", File.size("dup.csv"), mode: 'a')
			else
			#	log << "found duplicate for #{file[:name]}, different md5"
			#	unequal_files << "#{sf[:name]};#{sf[:size]};#{sf[:md5]};#{file[:name]};#{file[:size]};#{file[:md5]}"
				File.write('log.txt', "found duplicate for #{file[:name]}, different md5\n", File.size("log.txt"), mode: 'a')
				File.write("diff.csv", "#{sf[:name]};#{sf[:size]};#{sf[:md5]};#{file[:name]};#{file[:size]};#{file[:md5]}\n", File.size("diff.csv"), mode: 'a')
			end
		end
	end
	dupbar.increment!
end
=begin
open('nodup.csv', 'a') {|f|
	no_dup_files.each do |record|
		f.puts record
	end
}

open('equal_files.csv', 'a') {|f|
	equal_files.each do |record|
		f.puts record
	end
}

open('unequal_files.csv', 'a') {|f|
	unequal_files.each do |record|
		f.puts record
	end
}


open('log_dup.txt', 'a') {|f|
	log.each do |logrecord|
		f.puts logrecord
	end
}
=end