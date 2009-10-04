require 'shift_subtitle'

describe SubtitleShifter do
  
  source = "source.srt"
  dest = "dest.srt"

  after(:each) do
    File.delete(dest) if File.exists?(dest)
  end

  it "should format a given time to SRT time format" do
    subtitle_shifter = SubtitleShifter.new(["--operation", "add", "--time", "10,000", source, dest])
    subtitle_shifter.to_srt_format(Time.parse("01:23:45,678")) == "01:23:45,678"
  end

  it "should add amount of time to a given time" do
    subtitle_shifter = SubtitleShifter.new(["--operation", "add", "--time", "10,600", source, dest])
    t1 = subtitle_shifter.to_srt_format(subtitle_shifter.add(Time.parse("00:00:01,500")))
    t2 = subtitle_shifter.to_srt_format(subtitle_shifter.add(Time.parse("00:00:01,100")))
    t3 = subtitle_shifter.to_srt_format(subtitle_shifter.add(Time.parse("00:00:01,430")))
    t4 = subtitle_shifter.to_srt_format(subtitle_shifter.add(Time.parse("00:00:01,401")))
    t1.should == "00:00:12,100"
    t2.should == "00:00:11,700"
    t3.should == "00:00:12,030"
    t4.should == "00:00:12,001"
  end

  it "should subtract amount of time to a given time" do
    subtitle_shifter = SubtitleShifter.new(["--operation", "sub", "--time", "10,500", source, dest])
    t1 = subtitle_shifter.to_srt_format(subtitle_shifter.sub(Time.parse("00:00:11,500")))
    t2 = subtitle_shifter.to_srt_format(subtitle_shifter.sub(Time.parse("00:00:12,300")))
    t3 = subtitle_shifter.to_srt_format(subtitle_shifter.sub(Time.parse("00:00:10,500")))
    t1.should == "00:00:01,000"
    t2.should == "00:00:01,800"
    t3.should == "00:00:00,000"
    false
  end

  it "should return nil when trying to subtract an amount of time greater than a given time" do
    subtitle_shifter = SubtitleShifter.new(["--operation", "sub", "--time", "20,000", source, dest])
    subtitle_shifter.sub(Time.parse("00:00:10,000")).should == nil
    subtitle_shifter.sub(Time.parse("00:00:19,999")).should == nil
    subtitle_shifter.sub(Time.parse("00:00:20,000")).should_not == nil
  end

end



