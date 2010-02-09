require File.dirname(__FILE__) + '/spec_helper'

describe "A high-quality VBR encoder without a file" do
  
  before(:each) do
    @la = Lamer.new
    @la.vbr_quality 4
    @la.sample_rate 44.1
  end
  
  it "should ouput the correct command line options" do
   [ /-v/,/-V 4/,/--resample 44\.1/].each do |match|
     @la.argument_list.should =~ match
   end
  end

  it "should balk at returning the command line" do
    lambda {@la.command_line}.should raise_error(ArgumentError)
  end

  it "should balk at running the conversion" do
    lambda {@la.convert!}.should raise_error(ArgumentError)
  end

end

describe "An encoder with a file specified" do
  
  before(:each) do
    @la = Lamer.new
    @la.input_file "/Path/to/my/audio_file.wav"
  end
  
  it "should provide the right command line" do
    @la.command_line.should == "lame /Path/to/my/audio_file.wav"
  end
    
end

describe "An encoder with options and an input and output file specified" do
  
  before(:each) do
    @la = Lamer.new
    @la.encode_quality :high
    @la.input_file "/Path/to/my/audio_file.wav"
    @la.output_file "/Path/to/my/audio_file.mp3"
  end
  
  it "should provide the right command line" do
    @la.command_line.should == "lame -q 2 /Path/to/my/audio_file.wav /Path/to/my/audio_file.mp3"
  end
    
end

describe "An encoder sent various id3 information" do
  
  before(:each) do
    @la = Lamer.new
  end
  
  it "should set the title" do
    @la.id3 :title => "The All-Knowning Mind of Minolta"
    @la.id3_options[:title].should == "The All-Knowning Mind of Minolta"
    @la.id3_arguments.should == "--tt The All-Knowning Mind of Minolta"
  end
  
  it "should set multiple values" do
    @la.id3 :title => "The All-Knowning Mind of Minolta"
    @la.id3 :artist => "Tin Man Shuffler"
    @la.id3_options[:title].should == "The All-Knowning Mind of Minolta"
    @la.id3_options[:artist].should == "Tin Man Shuffler"
    @la.id3_arguments.should =~ /--tt The All-Knowning Mind of Minolta/
    @la.id3_arguments.should =~ /--ta Tin Man Shuffler/
  end
  
  it "should set the title, artist, album, year, comment, track number, and genre" do
    @la.id3 :title => 'title', :artist => 'artist', :album => 'album', 
                  :year => 1998, :comment => 'comment', :track_number => 1,
                  :genre => 'genre'
    [/--tt title/,/--ta artist/, /--tl album/,/--ty 1998/,/--tc comment/,/--tn 1/,/--tg genre/].each do |match|
      @la.id3_arguments.should =~ match
    end
  end
  
  it "should ignore nonsense values" do
    @la.id3 :bugz => "Not Real"
    @la.id3_arguments.should_not =~ /Real/
    @la.id3 :title => "Coolbeans"
    @la.id3_arguments.should =~ /Coolbeans/
  end
  
  it "should add v1 or v2 id3 tags as requested" do
    2.times do |n|
      @la.id3_version_only n
      @la.options[:id3_version].should == "--id3v#{n}-only"
    end
  end
  
  it "should allow adding v2 tags on top of default behaviour" do
    @la.id3_add_v2!
    @la.options[:id3_version].should == "--add-id3v2"
  end
  
  it "should not output id3_version unless tags are set" do
    @la.id3_version_only 1
    @la.argument_list.should == ""
  end
  
  describe "An encoder with id3 options and an input file" do
    before(:each) do
      @la = Lamer.new
      @la.id3 :title => 'title', :artist => 'artist', :album => 'album', 
                    :year => 1998, :comment => 'comment', :track_number => 1,
                    :genre => 'genre'
      @la.input_file File.join( File.dirname( __FILE__ ), 'test.mp3' )
    end
    
    it "should output those options to the command line" do
      [/--tt title/,/--ta artist/, /--tl album/,/--ty 1998/,/--tc comment/,/--tn 1/,/--tg genre/].each do |match|
        @la.command_line.should =~ match
      end
    end
  end
  
  describe "An encoder starting with an mp3 file" do
    before(:each) do
      @root = './spec/'
      begin
        File.delete File.join( File.dirname( __FILE__ ), 'output.mp3' )
      rescue
      end
      @la = Lamer.new
      @la.input_file "#{@root}test.mp3"
      @la.output_file "#{@root}output.mp3"
      @la.input_mp3!
    end
    
    it "should provide the right command line" do
      [/lame/,/--mp3input/, /-o/,/#{@root}test.mp3/,/#{@root}output.mp3/].each do |match|
        @la.command_line.should =~ match
      end
    end
    
    it "should successfully output a low bitrate version" do
      @la.bitrate 32
      @la.mode :mono
      File.exists?("#{@root}output.mp3").should == false 
      @la.convert!
      File.exists?("#{@root}output.mp3").should == true
    end
  end
  
  describe "The runtime environment" do
    it "should have lame version 3.9x installed" do
      version = `lame --help`
      version.should =~ /LAME/
      version.should =~ /3\.9+/
    end
  end
  
end