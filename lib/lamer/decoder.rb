# frozen_string_literal: true

class Lamer
  class Decoder
    # LAME can return up to 1152 samples per MP3 frame, but when decoding
    # a large chunk it can return many frames worth of samples at once.
    # Using a larger buffer to handle typical MP3 files.
    PCM_BUFFER_SIZE = 1152 * 128
    MP3_READ_SIZE = 16384

    attr_reader :hip, :mp3data

    def initialize
      @hip = FFI.hip_decode_init
      raise Error, "Failed to initialize HIP decoder" if @hip.null?

      @mp3data = FFI::Mp3Data.new
      @initialized = false

      ObjectSpace.define_finalizer(self, self.class.release(@hip))
    end

    def self.release(hip)
      proc { FFI.hip_decode_exit(hip) unless hip.null? }
    end

    def decode_file(input_path, output_path)
      File.open(input_path, "rb") do |input|
        File.open(output_path, "wb") do |output|
          left_buf = ::FFI::MemoryPointer.new(:short, PCM_BUFFER_SIZE)
          right_buf = ::FFI::MemoryPointer.new(:short, PCM_BUFFER_SIZE)
          mp3_buf = ::FFI::MemoryPointer.new(:uchar, MP3_READ_SIZE)

          first_frame = true
          channels = 2
          sample_rate = 44100

          until input.eof?
            data = input.read(MP3_READ_SIZE)
            break if data.nil? || data.empty?

            mp3_buf.put_bytes(0, data)

            if first_frame
              samples = FFI.hip_decode_headers(@hip, mp3_buf, data.bytesize, left_buf, right_buf, @mp3data)
              if samples > 0 || @mp3data[:header_parsed] != 0
                channels = @mp3data[:stereo]
                sample_rate = @mp3data[:samplerate]
                write_wav_header(output, channels, sample_rate)
                first_frame = false
              end
            else
              samples = FFI.hip_decode(@hip, mp3_buf, data.bytesize, left_buf, right_buf)
            end

            next unless samples > 0

            left_samples = left_buf.read_array_of_int16(samples)

            if channels == 2
              right_samples = right_buf.read_array_of_int16(samples)
              interleaved = left_samples.zip(right_samples).flatten
              output.write(interleaved.pack("s*"))
            else
              output.write(left_samples.pack("s*"))
            end
          end

          finalize_wav_header(output, channels)
        end
      end

      true
    end

    def decode_buffer(mp3_data)
      left_buf = ::FFI::MemoryPointer.new(:short, PCM_BUFFER_SIZE)
      right_buf = ::FFI::MemoryPointer.new(:short, PCM_BUFFER_SIZE)
      mp3_buf = ::FFI::MemoryPointer.new(:uchar, mp3_data.bytesize)
      mp3_buf.put_bytes(0, mp3_data)

      all_left = []
      all_right = []

      offset = 0
      remaining = mp3_data.bytesize

      while remaining > 0
        chunk_size = [remaining, MP3_READ_SIZE].min
        chunk_ptr = mp3_buf + offset

        samples = if !@initialized
          result = FFI.hip_decode_headers(@hip, chunk_ptr, chunk_size, left_buf, right_buf, @mp3data)
          @initialized = true if result >= 0 || @mp3data[:header_parsed] != 0
          result
        else
          FFI.hip_decode(@hip, chunk_ptr, chunk_size, left_buf, right_buf)
        end

        if samples > 0
          all_left.concat(left_buf.read_array_of_int16(samples))
          all_right.concat(right_buf.read_array_of_int16(samples)) if stereo?
        end

        offset += chunk_size
        remaining -= chunk_size
      end

      {
        left: all_left,
        right: stereo? ? all_right : nil,
        channels: @mp3data[:stereo],
        sample_rate: @mp3data[:samplerate],
        bitrate: @mp3data[:bitrate]
      }
    end

    def stereo?
      @mp3data[:stereo] == 2
    end

    def sample_rate
      @mp3data[:samplerate]
    end

    def bitrate
      @mp3data[:bitrate]
    end

    private

    def write_wav_header(file, channels, sample_rate)
      bits_per_sample = 16
      byte_rate = sample_rate * channels * bits_per_sample / 8
      block_align = channels * bits_per_sample / 8

      file.write("RIFF")
      file.write([0].pack("V")) # placeholder for file size
      file.write("WAVE")

      file.write("fmt ")
      file.write([16].pack("V"))
      file.write([1].pack("v")) # PCM
      file.write([channels].pack("v"))
      file.write([sample_rate].pack("V"))
      file.write([byte_rate].pack("V"))
      file.write([block_align].pack("v"))
      file.write([bits_per_sample].pack("v"))

      file.write("data")
      file.write([0].pack("V")) # placeholder for data size
    end

    def finalize_wav_header(file, channels)
      file_size = file.size
      data_size = file_size - 44

      file.seek(4)
      file.write([file_size - 8].pack("V"))

      file.seek(40)
      file.write([data_size].pack("V"))
    end
  end
end
