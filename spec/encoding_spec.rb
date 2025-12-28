# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Encoding" do
  describe "VBR encoder without a file" do
    subject(:lamer) do
      l = Lamer.new
      l.vbr_quality(4)
      l.sample_rate(44.1)
      l
    end

    it "records VBR options correctly" do
      expect(lamer.options[:vbr]).to eq(true)
      expect(lamer.options[:vbr_quality]).to eq(4)
      expect(lamer.options[:out_samplerate]).to eq(44100)
    end

    it "raises ArgumentError when convert! called without input file" do
      expect { lamer.convert! }.to raise_error(ArgumentError)
    end
  end

  describe "ID3 tags" do
    subject(:lamer) { Lamer.new }

    it "sets the title" do
      lamer.id3(title: "The All-Knowing Mind of Minolta")
      expect(lamer.id3_options[:title]).to eq("The All-Knowing Mind of Minolta")
    end

    it "sets multiple values" do
      lamer.id3(title: "The All-Knowing Mind of Minolta")
      lamer.id3(artist: "Tin Man Shuffler")
      expect(lamer.id3_options[:title]).to eq("The All-Knowing Mind of Minolta")
      expect(lamer.id3_options[:artist]).to eq("Tin Man Shuffler")
    end

    it "sets title, artist, album, year, comment, track number, and genre" do
      lamer.id3(
        title: "title",
        artist: "artist",
        album: "album",
        year: 1998,
        comment: "comment",
        track_number: 1,
        genre: "genre"
      )
      expect(lamer.id3_options[:title]).to eq("title")
      expect(lamer.id3_options[:artist]).to eq("artist")
      expect(lamer.id3_options[:album]).to eq("album")
      expect(lamer.id3_options[:year]).to eq(1998)
      expect(lamer.id3_options[:comment]).to eq("comment")
      expect(lamer.id3_options[:track_number]).to eq(1)
      expect(lamer.id3_options[:genre]).to eq("genre")
    end

    it "stores unknown values but they are ignored during encoding" do
      lamer.id3(bugz: "Not Real")
      expect(lamer.id3_options[:bugz]).to eq("Not Real")
      lamer.id3(title: "Coolbeans")
      expect(lamer.id3_options[:title]).to eq("Coolbeans")
    end

    it "sets ID3 version to v1 or v2 only" do
      2.times do |n|
        lamer.id3_version_only(n)
        expect(lamer.id3_options[:version]).to eq(n)
      end
    end

    it "allows adding v2 tags" do
      lamer.id3_add_v2!
      expect(lamer.id3_options[:add_v2]).to eq(true)
    end
  end

  describe "Integration tests", :integration do
    let(:spec_dir) { File.dirname(__FILE__) }
    let(:test_mp3) { File.join(spec_dir, "test.mp3") }
    let(:output_mp3) { File.join(spec_dir, "output.mp3") }

    before do
      File.delete(output_mp3) if File.exist?(output_mp3)
    end

    after do
      File.delete(output_mp3) if File.exist?(output_mp3)
    end

    describe "re-encoding MP3 file" do
      subject(:lamer) do
        l = Lamer.new
        l.input_file(test_mp3)
        l.output_file(output_mp3)
        l.input_mp3!
        l
      end

      it "marks input as MP3" do
        expect(lamer.options[:input_mp3]).to eq(true)
        expect(lamer.options[:copy]).to eq(true)
      end

      it "successfully outputs a low bitrate version", :slow do
        lamer.bitrate(32)
        lamer.mode(:mono)
        expect(File.exist?(output_mp3)).to eq(false)
        lamer.convert!
        expect(File.exist?(output_mp3)).to eq(true)
      end
    end
  end

  describe "Runtime environment" do
    it "has LAME 3.x installed" do
      version = Lamer.lame_version
      expect(version).to match(/^3\.\d+/)
    end
  end
end
