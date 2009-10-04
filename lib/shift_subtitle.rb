require 'time'
require 'optparse'

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
          puts 'Unsupported operation!'
          puts opts
          exit
        end
      end
      opts.on('-t', '--time TIME', 'The amount of time to shift in the format 11,222 where ''11'' is the amount of seconds and ''222'' the amount of milliseconds') do |time|
        if /^(\d{1,4}),(\d{3})$/ =~ time
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

  # Add the amount of time to the given time.
  def add(time)
    time + @time
  end

  # Subtracts the amount of time from the given time.
  # Returns nil if the amount of time is greater than the
  # given time.
  def sub(time)
    new_time = time - @time
    new_time.strftime("%Y%m%d") < time.strftime("%Y%m%d") ? nil : new_time
  end

  # Main method processing the shifting operation with the given parameters hash.
  def execute
    puts "Shifting SRT file: #{@source} to: #{@dest}"
    puts "operation: #{@operation} #{@time}"
    check_destination
    begin
      # The destination file is open in write mode
      File.open(@dest, 'w') do |dest|
        # The source file is open in read only mode
        File.open(@source, 'r') do |source|
          # For each line of the source file
          while line = source.gets
            # Each start/end time lines are modified according to the operation and the amount of time
            if /^(\d{2}:[0-5]\d:[0-5]\d,\d{3})\s-->\s(\d{2}:[0-5]\d:[0-5]\d,\d{3})$/ =~ line.strip
              new_start_time = send @operation, Time.parse($1)
              new_end_time = send @operation, Time.parse($2)
              if new_start_time.nil?
                raise "The amount of time you want to subtract is great than the time at which occurs the first subtitle."
                exit
              end
              dest.puts "#{to_srt_format(new_start_time)} --> #{to_srt_format(new_end_time)}"
            # Other lines (subtitle numbers and subtitles) are kept unchanged
            else
              dest.puts line
            end
          end
        end
      end
      puts "Done!"
    rescue => err
      File.delete @dest
      puts "ERROR: #{err}"
    end
  end

end

if __FILE__ == $0
  # Calling the main method with the parsed arguments
  SubtitleShifter.new(ARGV).execute
end