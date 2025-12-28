# frozen_string_literal: true

require_relative "lamer/version"
require_relative "lamer/error"
require_relative "lamer/ffi"
require_relative "lamer/encoder"
require_relative "lamer/decoder"

# Lamer is a Ruby wrapper around the LAME MP3 encoder library via FFI.
class Lamer
  # Valid MP3 bitrates in kbps
  MP3_BITRATES = [32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320].freeze

  # Valid sample rates in kHz
  SAMPLE_RATES = [8, 11.025, 12, 16, 22.05, 24, 32, 44.1, 48].freeze

  # Valid encoding quality values (0 = best/slowest, 9 = worst/fastest)
  ENCODING_QUALITY = (0..9).freeze

  # Valid VBR quality values (0 = best, 9 = worst)
  VBR_QUALITY = (0..9).freeze

  # Channel mode mappings
  CHANNELS = {
    mono: :mono,
    stereo: :stereo,
    joint: :joint_stereo,
    auto: :joint_stereo,
    mid_side: :dual_channel
  }.freeze

  # Replay gain options (not directly supported in FFI, kept for API compatibility)
  REPLAY_GAIN = {
    fast: :fast,
    accurate: :accurate,
    none: :none,
    clip_detect: :clip_detect,
    default: nil
  }.freeze

  attr_accessor :options, :id3_options

  def initialize
    @options = {}
    @id3_options = nil
    @input_file = nil
    @output_file = nil
  end

  # Set the output bitrate in kbps
  def bitrate(kbps)
    raise ArgumentError, "legal bitrates: #{MP3_BITRATES.join(', ')}" unless MP3_BITRATES.include?(kbps)

    @options[:bitrate] = kbps
  end

  # Set the output sample rate in kHz
  def sample_rate(rate)
    raise ArgumentError, "legal sample rates: #{SAMPLE_RATES.join(', ')}" unless SAMPLE_RATES.include?(rate)

    @options[:out_samplerate] = (rate * 1000).to_i
  end

  # Set encoding quality (0 = best/slowest, 9 = worst/fastest)
  # Also accepts :high (2) and :fast (7) as shortcuts
  def encode_quality(quality)
    quality_map = { high: 2, fast: 7 }
    quality = quality_map[quality] || quality
    raise ArgumentError, "legal qualities: #{ENCODING_QUALITY.to_a.join(', ')}" unless ENCODING_QUALITY.include?(quality)

    @options[:quality] = quality
  end

  # Set VBR quality (0 = best, 9 = worst)
  def vbr_quality(quality)
    raise ArgumentError, "legal qualities: #{VBR_QUALITY.to_a.join(', ')}" unless VBR_QUALITY.include?(quality)

    @options[:vbr_quality] = quality
    @options[:vbr] = true
  end

  # Set channel mode (:mono, :stereo, :joint, :auto, :mid_side)
  def mode(channels)
    @options[:mode] = CHANNELS[channels]
  end

  # Set replay gain mode (kept for API compatibility)
  def replay_gain(gain)
    @options[:replay_gain] = REPLAY_GAIN[gain]
  end

  # Set the input file path
  def input_file(filename)
    @input_file = filename
    mark_as_copy! if filename =~ /\.mp3$/i
  end

  # Set the output file path
  def output_file(filename)
    @output_file = filename
  end

  # Mark input as MP3 (for re-encoding)
  def input_mp3!
    @options[:input_mp3] = true
    mark_as_copy!
  end

  # Set input as raw PCM data
  def input_raw(sample_rate, swapbytes = false)
    @options[:input_raw] = true
    @options[:in_samplerate] = (sample_rate * 1000).to_i
    @options[:swapbytes] = swapbytes
  end

  # Mark the output as a copy (for MP3 to MP3 encoding)
  def mark_as_copy!
    @options[:copy] = true
  end

  # Set ID3 tag options
  def id3(opts)
    @id3_options = @id3_options ? @id3_options.merge(opts) : opts
  end

  # Set ID3 version (1 or 2 only)
  def id3_version_only(version)
    @id3_options ||= {}
    @id3_options[:version] = version
  end

  # Add ID3v2 tags
  def id3_add_v2!
    @id3_options ||= {}
    @id3_options[:add_v2] = true
  end

  # Set highpass filter frequency in kHz
  def highpass(width)
    @options[:highpass] = (width * 1000).to_i
  end

  # Set lowpass filter frequency in kHz
  def lowpass(width)
    @options[:lowpass] = (width * 1000).to_i
  end

  # Encode the input file to MP3
  def convert!
    raise ArgumentError, "No input file specified." unless @input_file

    encoder = Encoder.new(@options)
    encoder.apply_id3(@id3_options) if @id3_options && !@id3_options.empty?

    output = @output_file || @input_file.sub(/\.[^.]+$/, ".mp3")
    encoder.encode_file(@input_file, output)

    true
  end

  # Encode PCM samples directly to MP3 data (new capability)
  # left_samples and right_samples are arrays of 16-bit signed integers
  def encode_buffer(left_samples, right_samples = nil)
    encoder = Encoder.new(@options)
    encoder.apply_id3(@id3_options) if @id3_options && !@id3_options.empty?

    result = encoder.encode_short(left_samples, right_samples)
    result + encoder.flush
  end

  # Encode interleaved PCM samples directly to MP3 data
  def encode_buffer_interleaved(interleaved_samples)
    encoder = Encoder.new(@options)
    encoder.apply_id3(@id3_options) if @id3_options && !@id3_options.empty?

    result = encoder.encode_short_interleaved(interleaved_samples)
    result + encoder.flush
  end

  # Encode float samples directly to MP3 data (new capability)
  # samples are arrays of floats in range -1.0 to 1.0
  def encode_float_buffer(left_samples, right_samples = nil)
    encoder = Encoder.new(@options)
    encoder.apply_id3(@id3_options) if @id3_options && !@id3_options.empty?

    result = encoder.encode_float(left_samples, right_samples)
    result + encoder.flush
  end

  # Get LAME library version
  def self.lame_version
    FFI.get_lame_version
  end

  # Set decode mode for converting MP3 to WAV
  def decode_mp3!
    @options.clear
    @options[:decode_mp3] = true
  end

  # Decode an MP3 file to WAV
  # Must call decode_mp3! first, then input_file and output_file
  def decode!
    raise ArgumentError, "No input file specified." unless @input_file
    raise ConfigurationError, "Call decode_mp3! before decode!" unless @options[:decode_mp3]

    decoder = Decoder.new
    output = @output_file || @input_file.sub(/\.mp3$/i, ".wav")
    decoder.decode_file(@input_file, output)
  end

  # Decode MP3 data to PCM samples
  def decode_buffer(mp3_data)
    decoder = Decoder.new
    decoder.decode_buffer(mp3_data)
  end
end
