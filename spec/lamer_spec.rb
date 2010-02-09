require File.dirname(__FILE__) + '/spec_helper'

describe "A new Lamer" do
  
  before(:each) do
    @la = Lamer.new
  end
  
  it "should have a blank argument list" do
    @la.argument_list.empty?.should == true
  end
  
  it "should record valid bitrates" do
    @la.bitrate 128
    @la.options[:bitrate].should == "-b 128"
  end
  
  it "should record valid sample rates" do
    @la.sample_rate 44.1
    @la.options[:sample_rate].should == "--resample 44.1"
  end
  
  it "should record valid VBR quality" do
    @la.vbr_quality 5
    @la.options[:vbr_quality].should == "-V 5"
    @la.options[:vbr].should == "-v"
  end

  it "should record valid quality" do
    @la.encode_quality 1
    @la.options[:encode_quality].should == "-q 1"
  end
   
  it "should record valid quality" do
    @la.encode_quality 5
    @la.options[:encode_quality].should == "-q 5"
  end
  
  it "should record valid quality shortcut" do
    @la.encode_quality :high
    @la.options[:encode_quality].should == "-q 2"
    @la.encode_quality :fast
    @la.options[:encode_quality].should == "-q 7"
  end
   
  it "should balk at invalid bitrates" do
    lambda {@la.bitrate 113}.should raise_error(ArgumentError)
  end
  
  it "should balk at invalid sample rates" do
    lambda {@la.sample_rate 113}.should raise_error(ArgumentError)
  end

  it "should balk at invalid VBR qualities" do
    lambda {@la.vbr_quality 113}.should raise_error(ArgumentError)
  end
    
  it "should balk at invalid encode qualities" do
    lambda {@la.encode_quality 113}.should raise_error(ArgumentError)
  end
  
  it "should set mode to stereo or mono" do
    {:stereo => '-m s', :mono => '-m m', :joint => '-m j'}.each do |option, setting|
      @la.mode option
      @la.options[:mode].should == setting
    end
  end
  
  it "should set mode to nil on bad option" do
    @la.mode :bugz
    @la.options[:mode].should == nil
  end
  
  it "should accept flag that input is mp3" do
    @la.input_mp3!
    @la.options[:input_mp3].should == "--mp3input"
  end
  
  it "should accept an input filename" do
    @la.input_file "/Path/to/my/audio_file.wav"
    @la.command_line.should == "lame /Path/to/my/audio_file.wav"
  end

  it "should accept replygain options" do
    {:accurate => "--replaygain-accurate",
      :fast => "--replaygain-fast",
      :none => "--noreplaygain",
      :clip_detect => "--clipdetect",
      :default => nil
    }.each do |option, setting|
      @la.replay_gain option
      @la.options[:replay_gain].should == setting
    end
  end
  
  it "should accept raw PCM files" do
    @la.input_raw 44.1
    @la.options[:input_raw].should == "-r -s 44.1"
    @la.input_raw 32, true
    @la.options[:input_raw].should == "-r -s 32 -x"
  end
  
  it "should mark as copy when requested" do
    @la.mark_as_copy!
    @la.options[:copy].should == "-o"
  end
  it "should mark as copy when starting from a file ending in .mp3" do
    @la.input_file "/Path/to/my/audio_file.mp3"
    @la.options[:copy].should == "-o"
  end
  it "should mark as copy when starting from an mp3 file" do
    @la.input_mp3!
    @la.options[:copy].should == "-o"
  end  
  it "should not mark as copy when starting from a file not ending in .mp3" do
    @la.input_file "/Path/to/my/audio_file.aif"
    @la.options[:copy].should == nil
  end
  
  it "should output ogg files when requested" do
    @la.output_ogg!
    @la.options[:output_ogg].should == "--ogg"
  end
  
end

