#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'lamer'

EXAMPLES_DIR = __dir__
WAV_FILE = File.join(EXAMPLES_DIR, 'ff-16b-2c-44100hz.wav')
MP3_FILE = File.join(EXAMPLES_DIR, 'ff-16b-2c-44100hz.mp3')
ENCODED_MP3 = File.join(EXAMPLES_DIR, 'encoded_output.mp3')
DECODED_WAV = File.join(EXAMPLES_DIR, 'decoded_output.wav')

def cleanup
  [ENCODED_MP3, DECODED_WAV].each do |file|
    File.delete(file) if File.exist?(file)
  end
end

def main
  cleanup

  puts "LAME version: #{Lamer.lame_version}"
  puts

  # Encode WAV to MP3 with ID3 tags
  puts "Encoding #{File.basename(WAV_FILE)} to MP3..."
  encoder = Lamer.new(WAV_FILE, ENCODED_MP3, bitrate: 192, mode: :stereo)
  encoder.id3(
    title: 'Demo Track',
    artist: 'Lamer Gem',
    album: 'FFI Examples',
    year: 2024,
    track_number: 1,
    genre: 'Electronic',
    comment: 'Encoded with lamer gem'
  )
  encoder.convert!
  puts "Created: #{ENCODED_MP3} (#{File.size(ENCODED_MP3)} bytes)"
  puts

  # Verify ID3 tags by reading them back
  puts 'Verifying ID3 tags...'
  mp3_header = File.binread(ENCODED_MP3, 1024)
  if mp3_header.include?('ID3')
    puts '  ID3v2 tag present'
    puts "  Title found: #{mp3_header.include?('Demo Track')}"
    puts "  Artist found: #{mp3_header.include?('Lamer Gem')}"
    puts "  Album found: #{mp3_header.include?('FFI Examples')}"
  else
    puts '  No ID3v2 tag found'
  end
  puts

  # Decode MP3 to WAV
  puts "Decoding #{File.basename(MP3_FILE)} to WAV..."
  Lamer.decode(MP3_FILE, DECODED_WAV)
  puts "Created: #{DECODED_WAV} (#{File.size(DECODED_WAV)} bytes)"
  puts

  # Verify WAV header
  puts 'Verifying WAV output...'
  wav_header = File.binread(DECODED_WAV, 44)
  if wav_header.start_with?('RIFF') && wav_header.include?('WAVE')
    puts '  Valid WAV header'
    channels = wav_header[22, 2].unpack1('v')
    sample_rate = wav_header[24, 4].unpack1('V')
    bits_per_sample = wav_header[34, 2].unpack1('v')
    puts "  Channels: #{channels}"
    puts "  Sample rate: #{sample_rate} Hz"
    puts "  Bits per sample: #{bits_per_sample}"
  end
  puts

  puts 'Demo complete!'
ensure
  cleanup
end

main
