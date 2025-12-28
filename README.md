# Lamer

Ruby FFI bindings for the LAME MP3 encoder library.

Encode audio to MP3 directly from Ruby without shelling out to a command line tool. Supports encoding from WAV files, raw PCM data, or re-encoding existing MP3 files.

## Requirements

- Ruby 3.2 or later
- libmp3lame library installed on your system

## Installation

First, install the LAME library:

**macOS (Homebrew)**

```bash
brew install lame
```

**Ubuntu/Debian**

```bash
sudo apt-get install libmp3lame-dev
```

**Fedora/RHEL/CentOS**

```bash
sudo dnf install lame-devel
```

Then add the gem to your Gemfile:

```ruby
gem 'lamer'
```

Or install it directly:

```bash
gem install lamer
```

## Quick Start

```ruby
require 'lamer'

# Encode a WAV file to MP3
encoder = Lamer.new
encoder.bitrate(192)
encoder.mode(:stereo)
encoder.id3(title: "My Song", artist: "My Artist")
encoder.input_file("input.wav")
encoder.output_file("output.mp3")
encoder.convert!

# Decode an MP3 file to WAV
decoder = Lamer.new
decoder.decode_mp3!
decoder.input_file("input.mp3")
decoder.output_file("output.wav")
decoder.decode!
```

## Usage

### Basic Encoding

```ruby
require 'lamer'

lamer = Lamer.new
lamer.bitrate(128)
lamer.input_file("audio.wav")
lamer.output_file("audio.mp3")
lamer.convert!
```

### VBR Encoding

```ruby
lamer = Lamer.new
lamer.vbr_quality(2)  # 0 = best quality, 9 = smallest file
lamer.input_file("audio.wav")
lamer.output_file("audio.mp3")
lamer.convert!
```

### Setting Quality and Mode

```ruby
lamer = Lamer.new
lamer.bitrate(320)
lamer.encode_quality(:high)  # or 0-9, where 0 is best
lamer.mode(:stereo)          # :mono, :stereo, :joint, :auto
lamer.input_file("audio.wav")
lamer.output_file("audio.mp3")
lamer.convert!
```

### ID3 Tags

```ruby
lamer = Lamer.new
lamer.bitrate(192)
lamer.id3(
  title: "Song Title",
  artist: "Artist Name",
  album: "Album Name",
  year: 2024,
  track_number: 1,
  genre: "Rock"
)
lamer.input_file("audio.wav")
lamer.output_file("audio.mp3")
lamer.convert!
```

### Re-encoding MP3 Files

```ruby
lamer = Lamer.new
lamer.bitrate(64)
lamer.mode(:mono)
lamer.input_file("highquality.mp3")
lamer.output_file("lowquality.mp3")
lamer.convert!
```

### Decoding MP3 to WAV

```ruby
lamer = Lamer.new
lamer.decode_mp3!
lamer.input_file("audio.mp3")
lamer.output_file("audio.wav")
lamer.decode!
```

### In-Memory Encoding

Encode PCM samples directly without file I/O:

```ruby
lamer = Lamer.new
lamer.bitrate(128)

# 16-bit signed integer samples
left_channel = [0, 1000, 2000, 3000, ...]
right_channel = [0, 1000, 2000, 3000, ...]

mp3_data = lamer.encode_buffer(left_channel, right_channel)
File.binwrite("output.mp3", mp3_data)
```

### Float Sample Encoding

For audio processing pipelines that use floating point samples:

```ruby
lamer = Lamer.new
lamer.bitrate(256)

# Float samples in range -1.0 to 1.0
left_channel = [0.0, 0.5, 1.0, 0.5, ...]
right_channel = [0.0, 0.5, 1.0, 0.5, ...]

mp3_data = lamer.encode_float_buffer(left_channel, right_channel)
```

## Available Options

### Bitrate

Valid bitrates in kbps: 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320

```ruby
lamer.bitrate(128)
```

### Sample Rate

Valid sample rates in kHz: 8, 11.025, 12, 16, 22.05, 24, 32, 44.1, 48

```ruby
lamer.sample_rate(44.1)
```

### VBR Quality

Values 0-9, where 0 is highest quality and 9 is smallest file size.

```ruby
lamer.vbr_quality(2)
```

### Encoding Quality

Values 0-9, where 0 is slowest/best and 9 is fastest/worst. Also accepts :high (2) and :fast (7).

```ruby
lamer.encode_quality(:high)
```

### Channel Mode

Available modes: :mono, :stereo, :joint, :auto, :mid_side

```ruby
lamer.mode(:joint)
```

### Filters

Set highpass and lowpass filter frequencies in kHz:

```ruby
lamer.highpass(0.1)   # 100 Hz
lamer.lowpass(16.0)   # 16 kHz
```

## Version Information

```ruby
Lamer.lame_version  # Returns the LAME library version string
```

## Author

[Mauricio Gomes](http://github.com/mgomes)

## License

MIT License
