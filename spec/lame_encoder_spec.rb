$: << File.join( File.dirname( __FILE__ ), '../lib' )

require 'rubygems'
require_gem 'rspec'
require 'lame_encoder'

context "A new LameEncoder" do
  
  setup do
    @la = LameEncoder.new
  end
  
  specify "has a blank argument list" do
    @la.argument_list.should_be_empty
  end
  
  specify "records valid bitrates" do
    @la.bitrate 128
    @la.options[:bitrate].should_equal "-b 128"
  end
  
  specify "records valid sample rate" do
    @la.sample_rate 44.1
    @la.options[:sample_rate].should_equal "--resample 44.1"
  end
  
  specify "records valid VBR quality" do
    @la.vbr_quality 5
    @la.options[:vbr_quality].should_equal "-V 5"
    @la.options[:vbr].should_equal "-v"
  end

  specify "records valid quality" do
    @la.encode_quality 1
    @la.options[:encode_quality].should_equal "-q 1"
  end
   
  specify "records valid quality" do
    @la.encode_quality 5
    @la.options[:encode_quality].should_equal "-q 5"
  end
  
  specify "records valid quality shortcut" do
    @la.encode_quality :high
    @la.options[:encode_quality].should_equal "-q 2"
    @la.encode_quality :fast
    @la.options[:encode_quality].should_equal "-q 7"
  end
   
  specify "balks at invalid bitrate" do
    lambda {@la.bitrate 113}.should_raise ArgumentError
  end
  
  specify "balks at invalid sample rate" do
    lambda {@la.sample_rate 113}.should_raise ArgumentError
  end

  specify "balks at invalid VBR quality" do
    lambda {@la.vbr_quality 113}.should_raise ArgumentError
  end
    
  specify "balks at invalid encode quality" do
    lambda {@la.encode_quality 113}.should_raise ArgumentError
  end
  
  specify "sets mode to stereo or mono" do
    {:stereo => '-m s', :mono => '-m m', :joint => '-m j'}.each do |option, setting|
      @la.mode option
      @la.options[:mode].should_equal setting
    end
  end
  
  specify "sets mode to nil on bad option" do
    @la.mode :bugz
    @la.options[:mode].should_be nil
  end
  
  specify "decodes mp3s" do
    @la.decode_mp3!
    @la.options[:decode_mp3].should_equal "--decode"
    lambda {@la.options[:new_value] = 'something'}.should_raise TypeError
  end
  
  specify "decodes mp3s without other options" do
    @la.vbr_quality 4
    @la.decode_mp3!
    @la.options.length.should_equal 1
  end
  
  specify "accepts flag that input is mp3" do
    @la.input_mp3!
    @la.options[:input_mp3].should_equal "--mp3input"
  end
  
  specify "accepts an input filename" do
    @la.input_file "/Path/to/my/audio_file.wav"
    @la.command_line.should_equal "lame /Path/to/my/audio_file.wav"
  end

  specify "accepts replygain options" do
    {:accurate => "--replaygain-accurate",
      :fast => "--replaygain-fast",
      :none => "--noreplaygain",
      :clip_detect => "--clipdetect",
      :default => nil
    }.each do |option, setting|
      @la.replay_gain option
      @la.options[:replay_gain].should_equal setting
    end
  end
  
  specify "accepts raw PCM files" do
    @la.input_raw 44.1
    @la.options[:input_raw].should_equal "-r -s 44.1"
    @la.input_raw 32, true
    @la.options[:input_raw].should_equal "-r -s 32 -x"
  end
  
  specify "marks as copy when requested" do
    @la.mark_as_copy!
    @la.options[:copy].should_equal "-o"
  end
  specify "marks as copy when starting from a file ending in .mp3" do
    @la.input_file "/Path/to/my/audio_file.mp3"
    @la.options[:copy].should_equal "-o"
  end
  specify "marks as copy when starting from an mp3 file" do
    @la.input_mp3!
    @la.options[:copy].should_equal "-o"
  end  
  specify "does not mark as copy when starting from a file not ending in .mp3" do
    @la.input_file "/Path/to/my/audio_file.aif"
    @la.options[:copy].should_be_nil
  end
  
  specify "outputs ogg files when requested" do
    @la.output_ogg!
    @la.options[:output_ogg].should_equal "--ogg"
  end
  
end

context "A high-quality VBR encoder without a file" do
  
  setup do
    @la = LameEncoder.new
    @la.vbr_quality 4
    @la.sample_rate 44.1
  end
  
  specify "ouputs the correct command line options" do
   [ /-v/,/-V 4/,/--resample 44\.1/].each do |match|
     @la.argument_list.should_match match
   end
  end

  specify "balks at returning the command line" do
    lambda {@la.command_line}.should_raise ArgumentError
  end

  specify "balks at running the conversion" do
    lambda {@la.convert!}.should_raise ArgumentError
  end

end

context "An encoder with a file specified" do
  
  setup do
    @la = LameEncoder.new
    @la.input_file "/Path/to/my/audio_file.wav"
  end
  
  specify "provides the right command line" do
    @la.command_line.should_equal "lame /Path/to/my/audio_file.wav"
  end
    
end

context "An encoder with options and an input and output file specified" do
  
  setup do
    @la = LameEncoder.new
    @la.encode_quality :high
    @la.input_file "/Path/to/my/audio_file.wav"
    @la.output_file "/Path/to/my/audio_file.mp3"
  end
  
  specify "provides the right command line" do
    @la.command_line.should_equal "lame -q 2 /Path/to/my/audio_file.wav /Path/to/my/audio_file.mp3"
  end
    
end

context "An encoder sent various id3 information" do
  
  setup do
    @la = LameEncoder.new
  end
  
  specify "sets the title" do
    @la.id3 :title => "The All-Knowning Mind of Minolta"
    @la.id3_options[:title].should_equal "The All-Knowning Mind of Minolta"
    @la.id3_arguments.should_equal "--tt The All-Knowning Mind of Minolta"
  end
  
  specify "sets multiple values" do
    @la.id3 :title => "The All-Knowning Mind of Minolta"
    @la.id3 :artist => "Tin Man Shuffler"
    @la.id3_options[:title].should_equal "The All-Knowning Mind of Minolta"
    @la.id3_options[:artist].should_equal "Tin Man Shuffler"
    @la.id3_arguments.should_match /--tt The All-Knowning Mind of Minolta/
    @la.id3_arguments.should_match /--ta Tin Man Shuffler/
  end
  
  specify "sets title, artist, album, year, comment, track number, and genre" do
    @la.id3 :title => 'title', :artist => 'artist', :album => 'album', 
                  :year => 1998, :comment => 'comment', :track_number => 1,
                  :genre => 'genre'
    [/--tt title/,/--ta artist/, /--tl album/,/--ty 1998/,/--tc comment/,/--tn 1/,/--tg genre/].each do |match|
      @la.id3_arguments.should_match match
    end
  end
  
  specify "ignores nonsense values" do
    @la.id3 :bugz => "Not Real"
    @la.id3_arguments.should_not_match /Real/
    @la.id3 :title => "Coolbeans"
    @la.id3_arguments.should_match /Coolbeans/
  end
  
  specify "adds v1 or v2 id3 tags as requested" do
    2.times do |n|
      @la.id3_version_only n
      @la.options[:id3_version].should_equal "--id3v#{n}-only"
    end
  end
  
  specify "allows adding v2 tags on top of default behaviour" do
    @la.id3_add_v2!
    @la.options[:id3_version].should_equal "--add-id3v2"
  end
  
  specify "does not output id3_version unless tags are set" do
    @la.id3_version_only 1
    @la.argument_list.should_equal ""
  end
  
  context "An encoder with id3 options and an input file" do
    setup do
      @la = LameEncoder.new
      @la.id3 :title => 'title', :artist => 'artist', :album => 'album', 
                    :year => 1998, :comment => 'comment', :track_number => 1,
                    :genre => 'genre'
      @la.input_file File.join( File.dirname( __FILE__ ), 'test.mp3' )
    end
    
    specify "outputs those options to the command line" do
      [/--tt title/,/--ta artist/, /--tl album/,/--ty 1998/,/--tc comment/,/--tn 1/,/--tg genre/].each do |match|
        @la.command_line.should_match match
      end
    end
  end
  
  context "An encoder starting with an mp3 file" do
    setup do
      @root = './spec/'
      begin
        File.delete File.join( File.dirname( __FILE__ ), 'output.mp3' )
      rescue
      end
      @la = LameEncoder.new
      @la.input_file "#{@root}test.mp3"
      @la.output_file "#{@root}output.mp3"
      @la.input_mp3!
    end
    
    specify "provides the right command line" do
      [/lame/,/--mp3input/, /-o/,/#{@root}test.mp3/,/#{@root}output.mp3/].each do |match|
        @la.command_line.should_match match
      end
    end
    
    specify "successfully outputs a low bitrate version" do
      @la.bitrate 32
      @la.mode :mono
      File.should_not_exist "#{@root}output.mp3"
      @la.convert!
      File.should_exist "#{@root}output.mp3"
    end
  end
  
  context "The runtime environment" do
    specify "should have lame version 3.96 installed" do
      version = `lame --help`
      version.should_match /LAME/
      version.should_match /3\.96/
    end
  end
  
end

