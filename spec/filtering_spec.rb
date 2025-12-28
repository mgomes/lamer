# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Filtering" do
  subject(:lamer) { Lamer.new }

  describe "#highpass" do
    it "sets the highpass frequency in Hz" do
      lamer.highpass(0.905)
      expect(lamer.options[:highpass]).to eq(905)
    end
  end

  describe "#lowpass" do
    it "sets the lowpass frequency in Hz" do
      lamer.lowpass(0.205)
      expect(lamer.options[:lowpass]).to eq(205)
    end
  end
end
