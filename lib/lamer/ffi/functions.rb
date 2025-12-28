# frozen_string_literal: true

class Lamer
  module FFI
    # Core lifecycle functions
    attach_function :lame_init, [], :pointer
    attach_function :lame_init_params, [:pointer], :int
    attach_function :lame_close, [:pointer], :int

    # Version info
    attach_function :get_lame_version, [], :string
    attach_function :get_lame_short_version, [], :string

    # Input settings
    attach_function :lame_set_num_samples, [:pointer, :ulong], :int
    attach_function :lame_get_num_samples, [:pointer], :ulong
    attach_function :lame_set_in_samplerate, [:pointer, :int], :int
    attach_function :lame_get_in_samplerate, [:pointer], :int
    attach_function :lame_set_num_channels, [:pointer, :int], :int
    attach_function :lame_get_num_channels, [:pointer], :int

    # Output settings
    attach_function :lame_set_out_samplerate, [:pointer, :int], :int
    attach_function :lame_get_out_samplerate, [:pointer], :int

    # Quality and mode settings
    attach_function :lame_set_quality, [:pointer, :int], :int
    attach_function :lame_get_quality, [:pointer], :int
    attach_function :lame_set_brate, [:pointer, :int], :int
    attach_function :lame_get_brate, [:pointer], :int
    attach_function :lame_set_mode, [:pointer, :mpeg_mode], :int
    attach_function :lame_get_mode, [:pointer], :mpeg_mode

    # VBR settings
    attach_function :lame_set_VBR, [:pointer, :vbr_mode], :int
    attach_function :lame_get_VBR, [:pointer], :vbr_mode
    attach_function :lame_set_VBR_q, [:pointer, :int], :int
    attach_function :lame_get_VBR_q, [:pointer], :int
    attach_function :lame_set_VBR_quality, [:pointer, :float], :int
    attach_function :lame_get_VBR_quality, [:pointer], :float
    attach_function :lame_set_VBR_min_bitrate_kbps, [:pointer, :int], :int
    attach_function :lame_set_VBR_max_bitrate_kbps, [:pointer, :int], :int

    # Filtering
    attach_function :lame_set_lowpassfreq, [:pointer, :int], :int
    attach_function :lame_get_lowpassfreq, [:pointer], :int
    attach_function :lame_set_highpassfreq, [:pointer, :int], :int
    attach_function :lame_get_highpassfreq, [:pointer], :int

    # Psychoacoustic settings
    attach_function :lame_set_ATHonly, [:pointer, :int], :int
    attach_function :lame_set_ATHshort, [:pointer, :int], :int
    attach_function :lame_set_noATH, [:pointer, :int], :int

    # Encoding functions - 16-bit signed integer PCM
    attach_function :lame_encode_buffer, [
      :pointer,  # gfp (global flags pointer)
      :pointer,  # buffer_l (left channel, short*)
      :pointer,  # buffer_r (right channel, short*)
      :int,      # nsamples
      :pointer,  # mp3buf (output buffer)
      :int       # mp3buf_size
    ], :int

    attach_function :lame_encode_buffer_interleaved, [
      :pointer,  # gfp
      :pointer,  # pcm (interleaved short*)
      :int,      # nsamples (per channel)
      :pointer,  # mp3buf
      :int       # mp3buf_size
    ], :int

    # Encoding functions - IEEE float PCM
    attach_function :lame_encode_buffer_ieee_float, [
      :pointer,  # gfp
      :pointer,  # buffer_l (float*)
      :pointer,  # buffer_r (float*)
      :int,      # nsamples
      :pointer,  # mp3buf
      :int       # mp3buf_size
    ], :int

    attach_function :lame_encode_buffer_interleaved_ieee_float, [
      :pointer,  # gfp
      :pointer,  # pcm (interleaved float*)
      :int,      # nsamples (per channel)
      :pointer,  # mp3buf
      :int       # mp3buf_size
    ], :int

    # Flush encoder
    attach_function :lame_encode_flush, [
      :pointer,  # gfp
      :pointer,  # mp3buf
      :int       # mp3buf_size
    ], :int

    attach_function :lame_encode_flush_nogap, [
      :pointer,  # gfp
      :pointer,  # mp3buf
      :int       # mp3buf_size
    ], :int

    # ID3 tag functions
    attach_function :id3tag_init, [:pointer], :void
    attach_function :id3tag_add_v2, [:pointer], :void
    attach_function :id3tag_v1_only, [:pointer], :void
    attach_function :id3tag_v2_only, [:pointer], :void
    attach_function :id3tag_set_title, [:pointer, :string], :void
    attach_function :id3tag_set_artist, [:pointer, :string], :void
    attach_function :id3tag_set_album, [:pointer, :string], :void
    attach_function :id3tag_set_year, [:pointer, :string], :void
    attach_function :id3tag_set_comment, [:pointer, :string], :void
    attach_function :id3tag_set_track, [:pointer, :string], :void
    attach_function :id3tag_set_genre, [:pointer, :string], :void

    # HIP (LAME's Hip Is a Player) decoder functions for MP3 decoding
    attach_function :hip_decode_init, [], :pointer
    attach_function :hip_decode_exit, [:pointer], :int
    attach_function :hip_decode, [
      :pointer,  # hip (decoder handle)
      :pointer,  # mp3buf (input)
      :size_t,   # len (input size)
      :pointer,  # pcm_l (output left channel, short*)
      :pointer   # pcm_r (output right channel, short*)
    ], :int
    attach_function :hip_decode_headers, [
      :pointer,  # hip
      :pointer,  # mp3buf
      :size_t,   # len
      :pointer,  # pcm_l
      :pointer,  # pcm_r
      :pointer   # mp3data (mp3data_struct*)
    ], :int

    # MP3 data structure for decoder
    class Mp3Data < ::FFI::Struct
      layout :header_parsed, :int,
             :stereo, :int,
             :samplerate, :int,
             :bitrate, :int,
             :mode, :int,
             :mode_ext, :int,
             :framesize, :int,
             :nsamp, :ulong,
             :totalframes, :int,
             :framenum, :int
    end
  end
end
