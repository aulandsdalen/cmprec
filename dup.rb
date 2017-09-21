require 'csv'
require 'sequel'
require 'rdispatch'
require 'progress_bar'

LOGFILE = "compare.log"
DIFFCSV = "diff.csv"
DUPCSV = "dup.csv"
NODUPCSV = "nodup.csv"

print "postgres user? "
dbuser = gets.chomp
print "postgres password? "
dbpassword = gets.chomp 
print "postgres database? "
dbname = gets.chomp

DB = Sequel.connect("postgres://#{dbuser}:#{dbpassword}@localhost:5432/#{dbname}")

remotefiles = DB[:remotefiles]


puts "Loading list of files..."
files_array = remotefiles.all

dupbar = ProgressBar.new(files_array.length, :bar, :counter, :percentage, :elapsed,)
files_processed = 0

files_array.each do |file|
	fullname = file[:name]
	shortname = "%" + fullname.split("/").last
	similar_files = remotefiles.where(Sequel.like(:name, shortname)).all
	files_processed += 1
	if similar_files.count == 1
		# no files found
		IO.write(LOGFILE, "#{files_processed}: no duplicates for #{file[:name]}\n", mode: 'a')
		IO.write(NODUPCSV, "#{file[:name]};#{file[:size]};#{file[:md5]}\n")
	else
		similar_files.each do |sf|
			if sf[:md5] == file[:md5]
				if sf[:name] == file[:name]
					# #3
					IO.write(LOGFILE, "#{files_processed}: no duplicates for file #{file[:name]}\n", mode: 'a')
				else
					# #4
					IO.write(LOGFILE, "#{files_processed}: duplicate found for #{file[:name]} at #{sf[:name]}\n")
					IO.write(DUPCSV, "#{file[:name]};#{file[:size]};#{file[:md5]};#{sf[:name]};#{sf[:size]};#{sf[:md5]}\n")
				end
			elsif sf[:name] == file[:name]
				# WTF??
				IO.write(LOGFILE, "#{files_processed}: WTF?? #{file[:name]}\n")
			else
				# #2
				IO.write(LOGFILE, "#{files_processed}: duplicate with different md5 found for #{file[:md5]}\n")
				IO.write(DIFFCSV, "#{file[:name]};#{file[:size]};#{file[:md5]};#{sf[:name]};#{sf[:size]};#{sf[:md5]}\n")
			end	
		end
	end
	dupbar.increment!
end