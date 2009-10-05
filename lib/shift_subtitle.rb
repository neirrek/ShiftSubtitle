require 'time'
require 'optparse'

# Exception possibly thrown by the SubtitleShifter.
class ShiftSubtitleException < StandardError; end

# A class that does the shifting stuff on SRT files.
# It is instanciated using an array of args, tipically ARGV.
class SubtitleShifter

  # Parses the command line and returns a hash of parameters
  # to be used for processing the command.
  def initialize(args)
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: shift_subtitle.rb [options] source dest"
      opts.on('-o', '--operation [add|sub]', 'Operation ''add'' or ''sub'' to add or subtract a given amount of time') do |operation|
        if /^(add|sub)$/ =~ operation
          @operation = operation
        else
          puts "Unsupported operation #{operation}!"
          puts opts
          exit
        end
      end
      opts.on('-t', '--time TIME', 'The amount of time to shift in the format 11,222 where ''11'' is the amount of seconds and ''222'' the amount of milliseconds') do |time|
        if /^(\d{1,4}),(\d{3})$/ =~ time
          @raw_time = time
          @time = "#{$1}.#{$2}".to_f
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
    @source = args[0]
    @dest = args[1]
  end

  # Checks the existence of the destination file. If it already exists,
  # prompt the user whether he wants to overwrite it or not. If he does
  # not want to overwrite, the script exits with an 'Aborted!' message.
  def check_destination
    if File.exists?(@dest)
      overwrite = nil
      while overwrite.nil?
        print "WARNING: File #{@dest} already exists! Overwrite it? [YES|no]: "
        answer = gets.downcase.strip
        if /^(|y|yes)$/ =~ answer
          overwrite = true
        elsif /^(n|no)$/ =~ answer
          overwrite = false
        end
      end
      if !overwrite
        puts "Aborted!"
        exit
      end
    end
  end

  # Format a time to the SRT time format.
  def to_srt_format(time)
    "#{time.strftime("%H:%M:%S")},#{(time.usec / 1000).to_s.rjust(3, '0')}"
  end

  # Add the amount of time to the given SRT time and returns
  # the result to the SRT time format.
  def add(time)
    to_srt_format(Time.parse(time) + @time)
  end

  # Subtracts the amount of time from the given SRT time and
  # returns the result to the SRT time format. Returns nil
  # if the amount of time is greater than the given time.
  def sub(time)
    new_time = (initial_time = Time.parse(time)) - @time
    unless new_time.strftime("%Y%m%d") >= initial_time.strftime("%Y%m%d")
      raise ShiftSubtitleException, "The amount of time #{@raw_time} you want to subtract is greater than #{to_srt_format(initial_time)}, the time at which occurs the first subtitle."
    end
    to_srt_format(new_time)
  end

  # Converts a line from the source SRT file according to the amount of time
  # to be added/subtracted. Nothing is done if the line is not a time line.
  def convert_line(line)
    if /^(\d{2}:[0-5]\d:[0-5]\d,\d{3})\s-->\s(\d{2}:[0-5]\d:[0-5]\d,\d{3})$/ =~ line.strip
      convert_time_line $1, $2
    else
      line
    end
  end
  
  # Converts a time line from the source SRT file according to the amount of
  # time to be added/subtracted.
  def convert_time_line(from, to)
    "#{send @operation, from} --> #{send @operation, to}"
  end

  # Main method executing the shifting operation with the given parameters.
  def execute
    puts "Shifting SRT file: #{@source} to: #{@dest}"
    puts "operation: #{@operation} #{@raw_time}"
    check_destination
    begin
      # The destination file is open in write mode
      File.open(@dest, 'w') do |dest|
        # The source file is open in read only mode
        File.readlines(@source).each do |line|
          dest.puts convert_line(line)
        end
      end
      puts "Done!"
    rescue ShiftSubtitleException => err
      # In case of error, the destination file is deleted
      # and the error message is displayed.
      File.delete @dest
      puts "ERROR: #{err}"
    end
  end

end

if __FILE__ == $0
  SubtitleShifter.new(ARGV).execute
end
