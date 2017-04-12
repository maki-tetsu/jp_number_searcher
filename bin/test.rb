$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'jp_number_searcher'

SAMPLE_NUMBERS = [
  '4261-3780-0163',
  '4272-7759-0305',
  '4261-7117-1790',
  '303781005010'
]

def usage
  puts "Usage: #{$0}"
  exit(1)
end

unless ARGV.count == 0
  usage
end

STDOUT.sync = true

STDOUT.puts('Check slip numbers to japan post...')
started_at = Time.now
result = JpNumberSearcher.search(SAMPLE_NUMBERS)
finished_at = Time.now
STDOUT.puts('Done.')

result.each do |result|
  puts "#{result[:slip_number]}\t#{result[:last_updated_at]}\t#{result[:status_label]}\t#{result[:error_label]}"
end

puts "\n#{started_at.strftime("%Y-%m-%d %H:%M:%S")} - #{finished_at.strftime("%Y-%m-%d %H:%M:%S")}"
