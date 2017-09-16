# populate database w/ contents of CSV data files
=begin
	primary_key :id
	String :name
	Bigint :size
	String :md5
=end
require 'csv'
require 'sequel'
require 'progress_bar' # why not?

def get_true_data(str)
	md5hash = str.pop
	filesize = str.pop
	truefname = str.join(",")
	[truefname, filesize, md5hash]
end

def is_md5?(str)
	if str.scan(/^[a-f0-9]{32}$/).empty?
		false
	else
		true
	end
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

rlab_length = `wc -l "#{FILE_RLAB_DATA}"`.strip.split(' ')[0].to_i
rlab_import_bar = ProgressBar.new(rlab_length, :bar, :counter, :percentage, :elapsed,)

puts "populating rlab table"
File.foreach(FILE_RLAB_DATA) do |line|
	begin
		CSV.parse(line) do |row|
			md5hash = row.pop
			filesize = row.pop
			filename = row.join(",")
			unless is_md5?(md5hash)
				puts "error recovering md5 hash: #{row} was converted to #{filename}|#{filesize}|#{md5hash}"
				return 100
			end
			recoveredfiles.insert(:name => filename, :size => filesize, :md5 => md5hash)
			rlab_import_bar.increment!
		end
	rescue CSV::MalformedCSVError => e
		manualrow = line.split(",")
		md5hash = manualrow.pop
		filesize = manualrow.pop
		filename = manualrow.join(",")
		recoveredfiles.insert(:name => filename, :size => filesize, :md5 => md5hash)
		rlab_import_bar.increment!
	end
end

server_length = `wc -l "#{FILE_SERVER_DATA}"`.strip.split(' ')[0].to_i
server_import_bar = ProgressBar.new(server_length, :bar, :counter, :percentage, :elapsed,)

puts "populating remotefiles table"
File.foreach(FILE_SERVER_DATA) do |line|
	begin
		CSV.parse(line) do |row|
			md5hash = row.pop
			filesize = row.pop
			filename = row.join(",")
			unless is_md5?(md5hash)
				puts "error recovering md5 hash: #{row} was converted to #{filename}|#{filesize}|#{md5hash}"
				return 100
			end
			remotefiles.insert(:name => filename, :size => filesize, :md5 => md5hash)
			server_import_bar.increment!
		end
	rescue CSV::MalformedCSVError => e
		# defaulting to manual csv parsing
		manualrow = line.split(",")
		md5hash = manualrow.pop
		filesize = manualrow.pop
		filename = manualrow.join(",")
		remotefiles.insert(:name => filename, :size => filesize, :md5 => md5hash)
		server_import_bar.increment!
	end
end
