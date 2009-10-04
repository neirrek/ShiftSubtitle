require 'time'
require 'optparse'

# Utility method for printing a separator line.
def print_separator(width = 80)
  puts "-" * width
end

# Parses the command line and returns a hash of parameters
# to be used for processing the command.
def get_params(args)
  params = {}
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: shift_subtitle.rb [options] source dest"
    opts.on('-o', '--operation [add|sub]', 'Operation ''add'' or ''sub'' to add or subtract a given amount of time') do |operation|
      if /^(add|sub)$/ =~ operation
        params[:operation] = operation
      else
        puts 'Unsupported operation!'
        puts opts
        exit
      end
    end
    opts.on('-t', '--time TIME', 'The amount of time to shift in the format 11,222 where ''11'' is the amount of seconds and ''222'' the amount of milliseconds') do |time|
      if /^(\d{1,4}),(\d{3})$/ =~ time
        params[:time] = "#{$1}.#{$2}".to_f
      else
        puts 'Wrong time format!'
        puts opts
        exit
      end
    end
    opts.on_tail('-h', '--help', 'Display this screen') do
      puts opts
      exit
    end
  end
  parser.parse! args
  # It should remains the source and destination files in args
  if args.size != 2
    puts parser.help
    exit
  end
  params[:source] = args[0]
  params[:dest] = args[1]
  return params
end

# Adding some utility methods to the Time class
class Time
  # Format a time to the SRT time format
  def to_srt_format
    "#{strftime("%H:%M:%S")},#{(usec / 1000).to_s.rjust(3, '0')}"
  end

  # Add the given amount of time to the receiver
  def add(time)
    self + time
  end

  # Subtracts the given amount of time from the receiver.
  # Returns nil if the amount of time is greater than the
  # receiver.
  def sub(time)
    res = self - time
    res.strftime("%Y%m%d") < self.strftime("%Y%m%d") ? nil : res
  end
end

# Main method processing the shifting operation with the given parameters hash.
def do_shift_subtitle(params)
  print_separator
  puts "Shifting SRT file: #{params[:source]} to: #{params[:dest]}"
  puts "operation: #{params[:operation]} #{params[:time]}"
  print_separator
  begin
    # The destination file is open in write mode
    File.open(params[:dest], 'w') do |dest|
      # The source file is open in read only mode
      File.open(params[:source], 'r') do |source|
        # For each line of the source file
        while line = source.gets
          # Each start/end time lines are modified according to the operation and the amount of time
          if /^(\d{2}:[0-5]\d:[0-5]\d,\d{3})\s-->\s(\d{2}:[0-5]\d:[0-5]\d,\d{3})$/ =~line.strip
            new_start_time = Time.parse($1).send params[:operation], params[:time]
            new_end_time = Time.parse($2).send params[:operation], params[:time]
            if new_start_time.nil?
              raise "The amount of time you want to subtract is great than the time at which occurs the first subtitle."
              exit
            end
            dest.puts "#{new_start_time.to_srt_format} --> #{new_end_time.to_srt_format}"
          # Other lines (subtitle numbers and subtitles) are kept unchanged
          else
            dest.puts line
          end
        end
      end
    end
    puts "Done!"
  rescue => err
    File.delete params[:dest]
    puts "Error: #{err}"
  end
end

# Calling the main method with the parsed arguments
do_shift_subtitle get_params(ARGV)
