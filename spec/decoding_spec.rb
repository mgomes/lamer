require File.dirname(__FILE__) + '/spec_helper'

describe "A Lamer, used for decoding," do
	before(:each) do
	  @la = Lamer.new
	end

	it "should decode mp3s" do
	  @la.decode_mp3!
	  @la.options[:decode_mp3].should == "--decode"
	end

	it "should decode mp3s without other options" do
	  @la.vbr_quality 4
	  @la.decode_mp3!
	  @la.options.length.should == 1
	end
end