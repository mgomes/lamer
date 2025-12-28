# frozen_string_literal: true

class Lamer
  class Encoder
    FLUSH_BUFFER_SIZE = 7200
    OUTPUT_BUFFER_SAFETY_MARGIN = 1.25

    attr_reader :global_flags

    def initialize(options = {})
      @global_flags = FFI.lame_init
      raise Error, "Failed to initialize LAME encoder" if @global_flags.null?

      @initialized = false
      configure(options)

      ObjectSpace.define_finalizer(self, self.class.release(@global_flags))
    end

    def self.release(gfp)
      proc { FFI.lame_close(gfp) unless gfp.null? }
    end

    def configure(options)
      raise ConfigurationError, "Cannot configure after encoding has started" if @initialized

      FFI.lame_set_brate(@global_flags, options[:bitrate]) if options[:bitrate]
      FFI.lame_set_in_samplerate(@global_flags, options[:in_samplerate]) if options[:in_samplerate]
      FFI.lame_set_out_samplerate(@global_flags, options[:out_samplerate]) if options[:out_samplerate]
      FFI.lame_set_num_channels(@global_flags, options[:num_channels]) if options[:num_channels]
      FFI.lame_set_quality(@global_flags, options[:quality]) if options[:quality]

      if options[:mode]
        mode = case options[:mode]
               when :mono then :mono
               when :stereo then :stereo
               when :joint, :joint_stereo then :joint_stereo
               when :dual, :dual_channel then :dual_channel
               else options[:mode]
               end
        FFI.lame_set_mode(@global_flags, mode)
      end

      if options[:vbr]
        FFI.lame_set_VBR(@global_flags, :vbr_mtrh)
        FFI.lame_set_VBR_q(@global_flags, options[:vbr_quality]) if options[:vbr_quality]
      end

      FFI.lame_set_lowpassfreq(@global_flags, options[:lowpass]) if options[:lowpass]
      FFI.lame_set_highpassfreq(@global_flags, options[:highpass]) if options[:highpass]
    end

    def apply_id3(id3_options)
      raise ConfigurationError, "Cannot set ID3 tags after encoding has started" if @initialized

      FFI.id3tag_init(@global_flags)
      FFI.id3tag_add_v2(@global_flags)

      FFI.id3tag_set_title(@global_flags, id3_options[:title].to_s) if id3_options[:title]
      FFI.id3tag_set_artist(@global_flags, id3_options[:artist].to_s) if id3_options[:artist]
      FFI.id3tag_set_album(@global_flags, id3_options[:album].to_s) if id3_options[:album]
      FFI.id3tag_set_year(@global_flags, id3_options[:year].to_s) if id3_options[:year]
      FFI.id3tag_set_comment(@global_flags, id3_options[:comment].to_s) if id3_options[:comment]
      FFI.id3tag_set_track(@global_flags, id3_options[:track_number].to_s) if id3_options[:track_number]
      FFI.id3tag_set_genre(@global_flags, id3_options[:genre].to_s) if id3_options[:genre]

      if id3_options[:version] == 1
        FFI.id3tag_v1_only(@global_flags)
      elsif id3_options[:version] == 2
        FFI.id3tag_v2_only(@global_flags)
      end
    end

    def init_params!
      return if @initialized

      ret = FFI.lame_init_params(@global_flags)
      raise ConfigurationError, "Failed to initialize LAME parameters (error code: #{ret})" if ret < 0

      @initialized = true
    end

    def encode_short(left_samples, right_samples = nil)
      init_params!

      num_samples = left_samples.size
      right_samples ||= left_samples

      mp3buf_size = calculate_buffer_size(num_samples)
      mp3buf = ::FFI::MemoryPointer.new(:uchar, mp3buf_size)

      left_ptr = ::FFI::MemoryPointer.new(:short, num_samples)
      left_ptr.write_array_of_int16(left_samples)

      right_ptr = ::FFI::MemoryPointer.new(:short, num_samples)
      right_ptr.write_array_of_int16(right_samples)

      bytes = FFI.lame_encode_buffer(@global_flags, left_ptr, right_ptr, num_samples, mp3buf, mp3buf_size)
      raise EncodingError, "Encoding failed with error code: #{bytes}" if bytes < 0

      mp3buf.read_bytes(bytes)
    end

    def encode_short_interleaved(interleaved_samples)
      init_params!

      num_samples = interleaved_samples.size / 2

      mp3buf_size = calculate_buffer_size(num_samples)
      mp3buf = ::FFI::MemoryPointer.new(:uchar, mp3buf_size)

      pcm_ptr = ::FFI::MemoryPointer.new(:short, interleaved_samples.size)
      pcm_ptr.write_array_of_int16(interleaved_samples)

      bytes = FFI.lame_encode_buffer_interleaved(@global_flags, pcm_ptr, num_samples, mp3buf, mp3buf_size)
      raise EncodingError, "Encoding failed with error code: #{bytes}" if bytes < 0

      mp3buf.read_bytes(bytes)
    end

    def encode_float(left_samples, right_samples = nil)
      init_params!

      num_samples = left_samples.size
      right_samples ||= left_samples

      mp3buf_size = calculate_buffer_size(num_samples)
      mp3buf = ::FFI::MemoryPointer.new(:uchar, mp3buf_size)

      left_ptr = ::FFI::MemoryPointer.new(:float, num_samples)
      left_ptr.write_array_of_float(left_samples)

      right_ptr = ::FFI::MemoryPointer.new(:float, num_samples)
      right_ptr.write_array_of_float(right_samples)

      bytes = FFI.lame_encode_buffer_ieee_float(@global_flags, left_ptr, right_ptr, num_samples, mp3buf, mp3buf_size)
      raise EncodingError, "Encoding failed with error code: #{bytes}" if bytes < 0

      mp3buf.read_bytes(bytes)
    end

    def flush
      init_params!

      mp3buf = ::FFI::MemoryPointer.new(:uchar, FLUSH_BUFFER_SIZE)
      bytes = FFI.lame_encode_flush(@global_flags, mp3buf, FLUSH_BUFFER_SIZE)
      raise EncodingError, "Flush failed with error code: #{bytes}" if bytes < 0

      mp3buf.read_bytes(bytes)
    end

    def encode_file(input_path, output_path, decode_mp3: false)
      pcm_data = if decode_mp3 || input_path.end_with?(".mp3")
        read_mp3_file(input_path)
      else
        read_wav_file(input_path)
      end

      File.open(output_path, "wb") do |output|
        pcm_data[:samples].each_slice(pcm_data[:chunk_size]) do |chunk|
          if pcm_data[:channels] == 2
            mp3_data = encode_short_interleaved(chunk)
          else
            mp3_data = encode_short(chunk)
          end
          output.write(mp3_data)
        end
        output.write(flush)
      end
    end

    private

    def read_mp3_file(path)
      decoder = Lamer::Decoder.new
      result = decoder.decode_buffer(File.binread(path))

      channels = result[:channels] > 0 ? result[:channels] : 2
      sample_rate = result[:sample_rate] > 0 ? result[:sample_rate] : 44100

      samples = if channels == 2 && result[:right]
        result[:left].zip(result[:right]).flatten
      else
        result[:left]
      end

      FFI.lame_set_in_samplerate(@global_flags, sample_rate)
      FFI.lame_set_num_channels(@global_flags, channels)

      {
        samples: samples,
        channels: channels,
        sample_rate: sample_rate,
        chunk_size: sample_rate * channels
      }
    end

    def calculate_buffer_size(num_samples)
      ((num_samples * OUTPUT_BUFFER_SAFETY_MARGIN) + FLUSH_BUFFER_SIZE).ceil
    end

    def read_wav_file(path)
      File.open(path, "rb") do |file|
        riff = file.read(4)
        raise Error, "Not a valid WAV file: missing RIFF header" unless riff == "RIFF"

        file.read(4) # file size
        wave = file.read(4)
        raise Error, "Not a valid WAV file: missing WAVE format" unless wave == "WAVE"

        fmt_chunk = nil
        data_chunk = nil

        while !file.eof?
          chunk_id = file.read(4)
          break if chunk_id.nil? || chunk_id.size < 4

          chunk_size = file.read(4).unpack1("V")

          case chunk_id
          when "fmt "
            fmt_data = file.read(chunk_size)
            audio_format, channels, sample_rate, byte_rate, block_align, bits_per_sample = fmt_data.unpack("vvVVvv")
            fmt_chunk = {
              audio_format: audio_format,
              channels: channels,
              sample_rate: sample_rate,
              byte_rate: byte_rate,
              block_align: block_align,
              bits_per_sample: bits_per_sample
            }
          when "data"
            data_chunk = file.read(chunk_size)
            break
          else
            file.seek(chunk_size, IO::SEEK_CUR)
          end
        end

        raise Error, "Invalid WAV file: missing fmt chunk" unless fmt_chunk
        raise Error, "Invalid WAV file: missing data chunk" unless data_chunk
        raise Error, "Only 16-bit PCM WAV files are supported" unless fmt_chunk[:bits_per_sample] == 16

        FFI.lame_set_in_samplerate(@global_flags, fmt_chunk[:sample_rate])
        FFI.lame_set_num_channels(@global_flags, fmt_chunk[:channels])

        samples = data_chunk.unpack("s*")

        {
          samples: samples,
          channels: fmt_chunk[:channels],
          sample_rate: fmt_chunk[:sample_rate],
          chunk_size: fmt_chunk[:sample_rate] * fmt_chunk[:channels]
        }
      end
    end
  end
end
