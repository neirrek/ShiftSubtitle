$LOAD_PATH << File.expand_path("../lib", File.dirname(__FILE__))

require 'shift_subtitle.rb'

describe SubtitleShifter do
  
  before(:each) do
    @dest = "dest.srt"
    @subtitle_shifter = SubtitleShifter.new(["--operation", "add", "--time", "10,500", "test.srt", @dest])
  end

  after(:each) do
    File.delete(@dest) if File.exists?(@dest)
  end

  it "should format a given time to SRT time format" do
    @subtitle_shifter.to_srt_format(Time.parse("00:00:12,345")).should == "00:00:12,345"
    @subtitle_shifter.to_srt_format(Time.parse("01:23:45,678")).should == "01:23:45,678"
  end

  it "should add amount of time to a given time" do    
    @subtitle_shifter.add("00:00:01,500").should == "00:00:12,000"
    @subtitle_shifter.add("00:00:01,100").should == "00:00:11,600"
    @subtitle_shifter.add("00:00:01,530").should == "00:00:12,030"
    @subtitle_shifter.add("00:00:01,501").should == "00:00:12,001"
  end

  it "should subtract amount of time to a given time" do
    @subtitle_shifter.sub("00:00:11,500").should == "00:00:01,000"
    @subtitle_shifter.sub("00:00:12,300").should == "00:00:01,800"
    @subtitle_shifter.sub("00:00:10,500").should == "00:00:00,000"
  end

  it "should raise an error when trying to subtract an amount of time greater than a given time" do
    lambda {@subtitle_shifter.sub("00:00:08,000")}.should raise_error(ShiftSubtitleException, "The amount of time 10,500 you want to subtract is greater than 00:00:08,000, the time at which occurs the first subtitle.")
    lambda {@subtitle_shifter.sub("00:00:10,499")}.should raise_error(ShiftSubtitleException, "The amount of time 10,500 you want to subtract is greater than 00:00:10,499, the time at which occurs the first subtitle.")
    lambda {@subtitle_shifter.sub("00:00:10,500")}.should_not raise_error
  end
  
  it "should convert time lines but keep other lines unchanged" do
    @subtitle_shifter.convert_line("Hello World!").should == "Hello World!"
    @subtitle_shifter.convert_line("").should == ""
    @subtitle_shifter.convert_line("123").should == "123"
    @subtitle_shifter.convert_line("00:00:01,200 --> 00:00:02,300").should == "00:00:11,700 --> 00:00:12,800"  end

end
