require File.expand_path('../../../spec_helper', __FILE__)
require File.expand_path('../fixtures/classes', __FILE__)
require File.expand_path('../shared/write', __FILE__)
require File.expand_path('../shared/binwrite', __FILE__)

describe "IO#write on a file" do
  before :each do
    @filename = tmp("IO_syswrite_file") + $$.to_s
    File.open(@filename, "w") do |file|
      file.write("012345678901234567890123456789")
    end
    @file = File.open(@filename, "r+")
    @readonly_file = File.open(@filename)
  end

  after :each do
    @file.close
    @readonly_file.close
    rm_r @filename
  end

  # TODO: impl detail? discuss this with matz. This spec is useless. - rdavis
  # I agree. I've marked it not compliant on macruby, as we don't buffer input. -pthomson
  not_compliant_on :macruby do
    it "writes all of the string's bytes but buffers them" do
      written = @file.write("abcde")
      written.should == 5
      File.open(@filename) do |file|
        file.read.should == "012345678901234567890123456789"
        @file.fsync
        file.rewind
        file.read.should == "abcde5678901234567890123456789"
      end
    end
  end

  it "does not check if the file is writable if writing zero bytes" do
    lambda { @readonly_file.write("") }.should_not raise_error
  end

  it "returns a length of 0 when writing a blank string" do
    @file.write('').should == 0
  end
end

ruby_version_is "1.9.3" do
  describe "IO.write" do
    before :each do
      @filename = tmp("IO_write") + $$.to_s
    end
    
    after :each do
      rm_r @filename
    end
    
    it_behaves_like :io_binwrite, :write
    
    it "uses encoding from given options, if provided" do
      IO.write(@filename, 'hello', :encoding => 'UTF-16')
      IO.binread(@filename).should == "\xFE\xFF\x00h\x00e\x00l\x00l\x00o"
    end
    
    it "needs to be reviewed for spec completeness"
  end
end

describe "IO#write" do
  it_behaves_like :io_write, :write
end
