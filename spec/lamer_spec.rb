# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lamer do
  subject(:lamer) { described_class.new }

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
