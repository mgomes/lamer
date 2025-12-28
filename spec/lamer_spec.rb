# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lamer do
  subject(:lamer) { described_class.new }

  describe ".new" do
    it "accepts input and output file arguments" do
      l = described_class.new("input.wav", "output.mp3")
      expect(l.instance_variable_get(:@input_file)).to eq("input.wav")
      expect(l.instance_variable_get(:@output_file)).to eq("output.mp3")
    end

    it "accepts named arguments" do
      l = described_class.new(bitrate: 192, mode: :stereo, quality: 2)
      expect(l.options[:bitrate]).to eq(192)
      expect(l.options[:mode]).to eq(:stereo)
      expect(l.options[:quality]).to eq(2)
    end

    it "accepts vbr option" do
      l = described_class.new(vbr: 3)
      expect(l.options[:vbr_quality]).to eq(3)
      expect(l.options[:vbr]).to eq(true)
    end

    it "accepts id3 option" do
      l = described_class.new(id3: { title: "Test", artist: "Artist" })
      expect(l.id3_options[:title]).to eq("Test")
      expect(l.id3_options[:artist]).to eq("Artist")
    end

    it "accepts filter options" do
      l = described_class.new(highpass: 0.1, lowpass: 16.0)
      expect(l.options[:highpass]).to eq(100)
      expect(l.options[:lowpass]).to eq(16000)
    end

    it "yields self to a block" do
      l = described_class.new do |encoder|
        encoder.bitrate(256)
        encoder.mode(:mono)
      end
      expect(l.options[:bitrate]).to eq(256)
      expect(l.options[:mode]).to eq(:mono)
    end

    it "combines arguments and block" do
      l = described_class.new("input.wav", "output.mp3", bitrate: 128) do |encoder|
        encoder.mode(:stereo)
      end
      expect(l.instance_variable_get(:@input_file)).to eq("input.wav")
      expect(l.options[:bitrate]).to eq(128)
      expect(l.options[:mode]).to eq(:stereo)
    end
  end

  describe ".encode", :integration do
    let(:spec_dir) { File.dirname(__FILE__) }
    let(:test_mp3) { File.join(spec_dir, "test.mp3") }
    let(:output_mp3) { File.join(spec_dir, "class_method_output.mp3") }

    after do
      File.delete(output_mp3) if File.exist?(output_mp3)
    end

    it "encodes with named arguments" do
      described_class.encode(test_mp3, output_mp3, bitrate: 32, mode: :mono)
      expect(File.exist?(output_mp3)).to eq(true)
    end

    it "encodes with a block" do
      described_class.encode(test_mp3, output_mp3) do |l|
        l.bitrate(32)
        l.mode(:mono)
      end
      expect(File.exist?(output_mp3)).to eq(true)
    end
  end

  describe ".decode", :integration do
    let(:spec_dir) { File.dirname(__FILE__) }
    let(:test_mp3) { File.join(spec_dir, "test.mp3") }
    let(:output_wav) { File.join(spec_dir, "class_method_output.wav") }

    after do
      File.delete(output_wav) if File.exist?(output_wav)
    end

    it "decodes MP3 to WAV" do
      described_class.decode(test_mp3, output_wav)
      expect(File.exist?(output_wav)).to eq(true)
    end
  end

  describe "#bitrate" do
    it "records valid bitrates" do
      lamer.bitrate(128)
      expect(lamer.options[:bitrate]).to eq(128)
    end

    it "raises ArgumentError for invalid bitrates" do
      expect { lamer.bitrate(113) }.to raise_error(ArgumentError)
    end
  end

  describe "#sample_rate" do
    it "records valid sample rates" do
      lamer.sample_rate(44.1)
      expect(lamer.options[:out_samplerate]).to eq(44100)
    end

    it "raises ArgumentError for invalid sample rates" do
      expect { lamer.sample_rate(113) }.to raise_error(ArgumentError)
    end
  end

  describe "#vbr_quality" do
    it "records valid VBR quality" do
      lamer.vbr_quality(5)
      expect(lamer.options[:vbr_quality]).to eq(5)
      expect(lamer.options[:vbr]).to eq(true)
    end

    it "raises ArgumentError for invalid VBR qualities" do
      expect { lamer.vbr_quality(113) }.to raise_error(ArgumentError)
    end
  end

  describe "#encode_quality" do
    it "records valid quality" do
      lamer.encode_quality(1)
      expect(lamer.options[:quality]).to eq(1)
    end

    it "records quality 5" do
      lamer.encode_quality(5)
      expect(lamer.options[:quality]).to eq(5)
    end

    it "accepts :high and :fast shortcuts" do
      lamer.encode_quality(:high)
      expect(lamer.options[:quality]).to eq(2)

      lamer.encode_quality(:fast)
      expect(lamer.options[:quality]).to eq(7)
    end

    it "raises ArgumentError for invalid encode qualities" do
      expect { lamer.encode_quality(113) }.to raise_error(ArgumentError)
    end
  end

  describe "#mode" do
    it "sets mode to stereo, mono, or joint" do
      { stereo: :stereo, mono: :mono, joint: :joint_stereo }.each do |option, expected|
        lamer.mode(option)
        expect(lamer.options[:mode]).to eq(expected)
      end
    end

    it "sets mode to nil for unknown option" do
      lamer.mode(:bugz)
      expect(lamer.options[:mode]).to be_nil
    end
  end

  describe "#input_mp3!" do
    it "accepts flag that input is MP3" do
      lamer.input_mp3!
      expect(lamer.options[:input_mp3]).to eq(true)
    end

    it "marks as copy when input is MP3" do
      lamer.input_mp3!
      expect(lamer.options[:copy]).to eq(true)
    end
  end

  describe "#input_file" do
    it "marks as copy when file ends in .mp3" do
      lamer.input_file("/Path/to/my/audio_file.mp3")
      expect(lamer.options[:copy]).to eq(true)
    end

    it "does not mark as copy for non-MP3 files" do
      lamer.input_file("/Path/to/my/audio_file.aif")
      expect(lamer.options[:copy]).to be_nil
    end
  end

  describe "#replay_gain" do
    it "accepts replay gain options" do
      {
        accurate: :accurate,
        fast: :fast,
        none: :none,
        clip_detect: :clip_detect,
        default: nil
      }.each do |option, expected|
        lamer.replay_gain(option)
        expect(lamer.options[:replay_gain]).to eq(expected)
      end
    end
  end

  describe "#input_raw" do
    it "accepts raw PCM files" do
      lamer.input_raw(44.1)
      expect(lamer.options[:input_raw]).to eq(true)
      expect(lamer.options[:in_samplerate]).to eq(44100)

      lamer.input_raw(32, true)
      expect(lamer.options[:in_samplerate]).to eq(32000)
      expect(lamer.options[:swapbytes]).to eq(true)
    end
  end

  describe "#mark_as_copy!" do
    it "marks as copy when requested" do
      lamer.mark_as_copy!
      expect(lamer.options[:copy]).to eq(true)
    end
  end

  describe "#highpass" do
    it "sets highpass filter frequency" do
      lamer.highpass(10)
      expect(lamer.options[:highpass]).to eq(10000)
    end
  end

  describe "#lowpass" do
    it "sets lowpass filter frequency" do
      lamer.lowpass(15)
      expect(lamer.options[:lowpass]).to eq(15000)
    end
  end

  describe "#convert!" do
    it "raises ArgumentError when no input file specified" do
      expect { lamer.convert! }.to raise_error(ArgumentError, /No input file specified/)
    end
  end

  describe ".lame_version" do
    it "returns LAME version string" do
      version = described_class.lame_version
      expect(version).to match(/^3\.\d+/)
    end
  end
end
