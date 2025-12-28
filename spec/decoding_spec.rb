# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Decoding" do
  subject(:lamer) { Lamer.new }

  describe "#decode_mp3!" do
    it "sets decode mode" do
      lamer.decode_mp3!
      expect(lamer.options[:decode_mp3]).to eq(true)
    end

    it "clears other options when called" do
      lamer.vbr_quality(4)
      lamer.decode_mp3!
      expect(lamer.options.length).to eq(1)
    end
  end

  describe "#decode!", :integration do
    let(:spec_dir) { File.dirname(__FILE__) }
    let(:test_mp3) { File.join(spec_dir, "test.mp3") }
    let(:output_wav) { File.join(spec_dir, "output.wav") }

    before do
      File.delete(output_wav) if File.exist?(output_wav)
    end

    after do
      File.delete(output_wav) if File.exist?(output_wav)
    end

    it "decodes MP3 to WAV" do
      lamer.decode_mp3!
      lamer.input_file(test_mp3)
      lamer.output_file(output_wav)
      expect(File.exist?(output_wav)).to eq(false)
      lamer.decode!
      expect(File.exist?(output_wav)).to eq(true)
    end
  end
end
