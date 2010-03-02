require File.dirname(__FILE__) + '/spec_helper'

describe "A highpass filter" do
  before(:each) do
    @la = Lamer.new
  end
  
  it "should set the highpass frequency" do
    @la.highpass(0.905)
    @la.options[:highpass].should == "--highpass 0.905"
  end
end

describe "A lowpass filter" do
  before(:each) do
    @la = Lamer.new
  end
  
  it "should set the lowpass frequency" do
    @la.lowpass(0.205)
    @la.options[:lowpass].should == "--lowpass 0.205"
  end
end