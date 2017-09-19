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

def find_similar(flist)
	flist.each do |file|
		fullname = file[:name]
		shortname = "%" + fullname.split("/").last
		similar_files = remotefiles.where(Sequel.like(:name, shortname)).all
			if similar_files.empty?
				log << "no duplicates for #{file[:name]}"
				no_dup_files << "#{file[:name]};#{file[:size]};#{file[:md5]}"
			else
				similar_files.each do |sf|
					if sf[:md5] == file[:md5]
						log << "found duplicate for #{file[:name]}"
						equal_files << "#{sf[:name]};#{sf[:size]};#{sf[:md5]};#{file[:name]};#{file[:size]};#{file[:md5]}"
					else
						log << "found duplicate for #{file[:name]}, different md5"
						unequal_files << "#{sf[:name]};#{sf[:size]};#{sf[:md5]};#{file[:name]};#{file[:size]};#{file[:md5]}"
					end
				end
			end
		dupbar.increment!
	end
end

puts "Loading list of files..."
files_array = remotefiles.all

dupbar = ProgressBar.new(files_array.length, :bar, :counter, :percentage, :elapsed,)
=begin
files_array.each do |file|
	fullname = file[:name]
	shortname = "%" + fullname.split("/").last
	similar_files = remotefiles.where(Sequel.like(:name, shortname)).all
	if similar_files.empty?
		log << "no duplicates for #{file[:name]}"
		no_dup_files << "#{file[:name]};#{file[:size]};#{file[:md5]}"
	else
		similar_files.each do |sf|
			if sf[:md5] == file[:md5]
				log << "found duplicate for #{file[:name]}"
				equal_files << "#{sf[:name]};#{sf[:size]};#{sf[:md5]};#{file[:name]};#{file[:size]};#{file[:md5]}"
			else
				log << "found duplicate for #{file[:name]}, different md5"
				unequal_files << "#{sf[:name]};#{sf[:size]};#{sf[:md5]};#{file[:name]};#{file[:size]};#{file[:md5]}"
			end
		end
	end
	dupbar.increment!
end
=end
threads = []
split_data = files_array.each_slice((files_array.size/8.0).round).to_a

split_data.each do |ds|
	puts "new thread"
	threads << Thread.new do
		ds.each do |file|
			fullname = file[:name]
			shortname = "%" + fullname.split("/").last
			similar_files = remotefiles.where(Sequel.like(:name, shortname)).all
				if similar_files.empty?
					log << "no duplicates for #{file[:name]}"
					no_dup_files << "#{file[:name]};#{file[:size]};#{file[:md5]}"
				else
					similar_files.each do |sf|
						if sf[:md5] == file[:md5]
							log << "found duplicate for #{file[:name]}"
							equal_files << "#{sf[:name]};#{sf[:size]};#{sf[:md5]};#{file[:name]};#{file[:size]};#{file[:md5]}"
						else
							log << "found duplicate for #{file[:name]}, different md5"
							unequal_files << "#{sf[:name]};#{sf[:size]};#{sf[:md5]};#{file[:name]};#{file[:size]};#{file[:md5]}"
						end
				end
			end
			dupbar.increment!
		end
	end
end

threads.each(&:join)


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