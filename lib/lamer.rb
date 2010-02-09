class Lamer
  
  # These constants come from the LAME documentation
  MP3_Bitrates = [32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320]
  Sample_Rates = [8, 11.025, 12, 16, 22.05, 24, 32, 44.1, 48]
  Encoding_Quality = (0..9)
  VBR_Quality = (0..6)
  Channels = {:mono => 'm', :stereo => 's', :joint => 'j', :auto => 'a', :mid_side => 'f'}
  Replay_Gain = {:fast => "--replaygain-fast", :accurate => "--replaygain-accurate", 
                 :none => "--noreplaygain", :clip_detect =>  "--clipdetect", :default => nil}

  attr_accessor :options, :id3_options 
  
  def initialize
    @options = {}
  end
  
  def argument_list
    @options.delete :id3_version unless @id3_options
    @options.collect {|k,v| v}.join(' ')
  end
  
  def command_line
    raise ArgumentError, "No input file specified." unless @input_file
    ['lame', argument_list, @input_file, @output_file, id3_arguments].select{|x| !(x.nil? || x.empty?)}.join(' ')
  end
  
  def convert!
    system command_line
  end
  
  # methods for setting options on the encoder
  
  def sample_rate(rate)
    raise ArgumentError unless Sample_Rates.include? rate
    @options[:sample_rate] = "--resample #{rate}"
  end
  
  def bitrate(kbps)
    raise ArgumentError, "legal bitrates: #{MP3_Bitrates.join(', ')}" unless MP3_Bitrates.include? kbps
    @options[:bitrate] = "-b #{kbps}"
  end
  
  def encode_quality(quality)
    quality_keys = Hash.new { |h,k| k }.merge( { :high => 2, :fast => 7 } )
    quality = quality_keys[quality]
    raise ArgumentError, "legal qualities: #{Encoding_Quality.to_a.join(', ')}" unless Encoding_Quality.include? quality
    @options[:encode_quality] = "-q #{quality}"
  end
  
  def vbr_quality(quality)
    raise ArgumentError, "legal qualities: #{VBR_Quality.to_a.join(', ')}" unless VBR_Quality.include? quality
    @options[:vbr_quality], @options[:vbr] = "-V #{quality}", "-v"
  end
  
  def mode(channels)
    @options[:mode] = Channels[channels] ? "-m #{Channels[channels]}" : nil
  end

  def replay_gain(gain)
    @options[:replay_gain] = Replay_Gain[gain]
  end

  # options for dealing with the input and output files

  def input_file(filename)
    @input_file = filename
    mark_as_copy! if filename =~ /\.mp3$/
  end
  
  def output_file(filename)
    @output_file = filename
  end

  def decode_mp3!
    @options.clear
    @options[:decode_mp3] = "--decode"
  end
  
  def output_ogg!
    @options[:output_ogg] = "--ogg"
  end
  
  def input_mp3!
    @options[:input_mp3] = "--mp3input"
    mark_as_copy!
  end
  
  def input_raw(sample_rate, swapbytes = false)
    @options[:input_raw] = "-r -s #{sample_rate}#{' -x' if swapbytes}"
  end
  
  def mark_as_copy!
    @options[:copy] = "-o"
  end
  
  # id3 options
  
  def id3 options 
    @id3_options = @id3_options ? @id3_options.merge(options) : options
  end
  
  def id3_arguments
    id3_fields = { :title => 'tt', :artist => 'ta', :album => 'tl', 
                  :year => 'ty', :comment => 'tc', :track_number => 'tn',
                  :genre => 'tg' }
    return nil if @id3_options.nil? || @id3_options.empty?
    @id3_options.select{|k,v| id3_fields[k]}.collect {|k,v| "--#{id3_fields[k]} #{v}"}.join(' ')
  end
  
  def id3_version_only version
    @options[:id3_version] = "--id3v#{version}-only"
  end
  
  def id3_add_v2!
    @options[:id3_version] = "--add-id3v2"
  end
  
end