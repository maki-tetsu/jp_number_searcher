$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'jp_number_searcher'

def usage
  puts "Usage: #{$0} FILE_PTH"
  puts "\tFILE_PATH: Include slip numbers for Japan Post a number by a line."
  exit(1)
end

unless ARGV.count == 1
  usage
end

file_path = ARGV.shift

STDOUT.sync = true
STDOUT.write("Reading slip numbers from file(#{file_path})...")
slip_numbers = File.readlines(file_path)
STDOUT.puts('Done.')
STDOUT.puts("Read #{slip_numbers.count} numbers from file.")

STDOUT.puts('Check slip numbers to japan post...')
started_at = Time.now
result = JpNumberSearcher.search(slip_numbers)
finished_at = Time.now
STDOUT.puts('Done.')

result.each do |result|
  puts "#{result[:slip_number]}\t#{result[:last_updated_at]}\t#{result[:status_label]}\t#{result[:error]}"
end

puts "\n#{started_at.strftime("%Y-%m-%d %H:%M:%S")} - #{finished_at.strftime("%Y-%m-%d %H:%M:%S")}"
