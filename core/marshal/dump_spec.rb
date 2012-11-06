# -*- coding: US-ASCII -*-
require File.expand_path('../../../spec_helper', __FILE__)
require File.expand_path('../fixtures/marshal_data', __FILE__)

describe "Marshal.dump" do
  it "dumps nil" do
    Marshal.dump(nil).should == "\004\b0"
  end

  it "dumps true" do
    Marshal.dump(true).should == "\004\bT"
  end

  it "dumps false" do
    Marshal.dump(false).should == "\004\bF"
  end

  describe "with a Fixnum" do
    it "dumps a Fixnum" do
      [ [Marshal,  0,       "\004\bi\000"],
        [Marshal,  5,       "\004\bi\n"],
        [Marshal,  8,       "\004\bi\r"],
        [Marshal,  122,     "\004\bi\177"],
        [Marshal,  123,     "\004\bi\001{"],
        [Marshal,  1234,    "\004\bi\002\322\004"],
        [Marshal, -8,       "\004\bi\363"],
        [Marshal, -123,     "\004\bi\200"],
        [Marshal, -124,     "\004\bi\377\204"],
        [Marshal, -1234,    "\004\bi\376.\373"],
        [Marshal, -4516727, "\004\bi\375\211\024\273"],
        [Marshal,  2**8,    "\004\bi\002\000\001"],
        [Marshal,  2**16,   "\004\bi\003\000\000\001"],
        [Marshal,  2**24,   "\004\bi\004\000\000\000\001"],
        [Marshal, -2**8,    "\004\bi\377\000"],
        [Marshal, -2**16,   "\004\bi\376\000\000"],
        [Marshal, -2**24,   "\004\bi\375\000\000\000"],
      ].should be_computed_by(:dump)
    end

    platform_is :wordsize => 64 do
      it "dumps a positive Fixnum > 31 bits as a Bignum" do
        Marshal.dump(2**31 + 1).should == "\x04\bl+\a\x01\x00\x00\x80"
      end

      it "dumps a negative Fixnum > 31 bits as a Bignum" do
        Marshal.dump(-2**31 - 1).should == "\x04\bl-\a\x01\x00\x00\x80"
      end
    end
  end

  describe "with a Symbol" do
    it "dumps a Symbol" do
      Marshal.dump(:symbol).should == "\004\b:\vsymbol"
    end

    it "dumps a big Symbol" do
      Marshal.dump(('big' * 100).to_sym).should == "\004\b:\002,\001#{'big' * 100}"
    end

    ruby_version_is "1.9" do
      it "dumps an encoded Symbol" do
        Marshal.dump("\u2192".encode("utf-8").to_sym).should == "\x04\bI:\b\xE2\x86\x92\x06:\x06ET"
      end
    end
  end

  it "dumps an extended_object" do
    Marshal.dump(Object.new.extend(Meths)).should == "\x04\be:\nMethso:\vObject\x00"
  end
  
  it "dumps an object that has had an ivar added and removed as though the ivar never was set" do
    obj = Object.new
    initial = Marshal.dump(obj)
    obj.instance_variable_set(:@ivar, 1)
    Marshal.dump(obj).should == "\004\bo:\vObject\006:\n@ivari\006"
    obj.send :remove_instance_variable, :@ivar
    Marshal.dump(obj).should == initial
  end

  describe "with an object responding to #marshal_dump" do
    it "dumps the object returned by #marshal_dump" do
      Marshal.dump(UserMarshal.new).should == "\x04\bU:\x10UserMarshal:\tdata"
    end

    it "does not use Class#name" do
      UserMarshal.should_not_receive(:name)
      Marshal.dump(UserMarshal.new)
    end
  end

  describe "with an object responding to #_dump" do
    it "dumps the object returned by #marshal_dump" do
      Marshal.dump(UserDefined.new).should == "\004\bu:\020UserDefined\022\004\b[\a:\nstuff;\000"
    end

    it "raises a TypeError if _dump returns a non-string" do
      m = mock("marshaled")
      m.should_receive(:_dump).and_return(0)
      lambda { Marshal.dump(m) }.should raise_error(TypeError)
    end

    it "favors marshal_dump over _dump" do
      m = mock("marshaled")
      m.should_receive(:marshal_dump).and_return(0)
      m.should_not_receive(:_dump)
      Marshal.dump(m)
    end
  end

  describe "with a Class" do
    it "dumps a builtin Class" do
      Marshal.dump(String).should == "\004\bc\vString"
    end

    it "dumps a user Class" do
      Marshal.dump(UserDefined).should == "\x04\bc\x10UserDefined"
    end

    it "dumps a nested Class" do
      Marshal.dump(UserDefined::Nested).should == "\004\bc\030UserDefined::Nested"
    end

    it "raises TypeError with an anonymous Class" do
      lambda { Marshal.dump(Class.new) }.should raise_error(TypeError)
    end

    it "raises TypeError with a singleton Class" do
      lambda { Marshal.dump(class << self; self end) }.should raise_error(TypeError)
    end
  end

  describe "with a Module" do
    it "dumps a builtin Module" do
      Marshal.dump(Marshal).should == "\004\bm\fMarshal"
    end

    it "raises TypeError with an anonymous Module" do
      lambda { Marshal.dump(Module.new) }.should raise_error(TypeError)
    end
  end

  describe "with a Float" do
    it "dumps a Float" do
      [ [Marshal,  0.0,            "\004\bf\0060"],
        [Marshal, -0.0,            "\004\bf\a-0"],
        [Marshal,  1.0,            "\004\bf\0061"],
        [Marshal,  infinity_value, "\004\bf\binf"],
        [Marshal, -infinity_value, "\004\bf\t-inf"],
        [Marshal,  nan_value,      "\004\bf\bnan"],
      ].should be_computed_by(:dump)
    end

    ruby_version_is ""..."1.9" do
      it "dumps a Float" do
        [ [Marshal, 8323434.342,        "\004\bf\0328323434.3420000002\000S\370"],
          [Marshal, 1.0799999999999912, "\004\bf\0321.0799999999999912\000\341 "],
        ].should be_computed_by(:dump)
      end
    end
  end

  describe "with a Bignum" do
    it "dumps a Bignum" do
      [ [Marshal, -4611686018427387903,    "\004\bl-\t\377\377\377\377\377\377\377?"],
        [Marshal, -2361183241434822606847, "\004\bl-\n\377\377\377\377\377\377\377\377\177\000"],
      ].should be_computed_by(:dump)
    end

    ruby_version_is "1.9" do
      it "dumps a Bignum" do
        [ [Marshal,  2**64, "\004\bl+\n\000\000\000\000\000\000\000\000\001\000"],
          [Marshal,  2**90, "\004\bl+\v#{"\000" * 11}\004"],
          [Marshal, -2**63, "\004\bl-\t\000\000\000\000\000\000\000\200"],
          [Marshal, -2**64, "\004\bl-\n\000\000\000\000\000\000\000\000\001\000"],
        ].should be_computed_by(:dump)
      end
    end
  end

  describe "with a String" do
    it "dumps a blank String" do
      Marshal.dump(encode("", "binary")).should == "\004\b\"\000"
    end

    it "dumps a short String" do
      Marshal.dump(encode("short", "binary")).should == "\004\b\"\012short"
    end

    it "dumps a long String" do
      Marshal.dump(encode("big" * 100, "binary")).should == "\004\b\"\002,\001#{"big" * 100}"
    end

    it "dumps a String extended with a Module" do
      Marshal.dump(encode("".extend(Meths), "binary")).should == "\004\be:\nMeths\"\000"
    end

    it "dumps a String subclass" do
      Marshal.dump(encode(UserString.new, "binary")).should == "\004\bC:\017UserString\"\000"
    end

    it "dumps a String subclass extended with a Module" do
      Marshal.dump(encode(UserString.new.extend(Meths), "binary")).should == "\004\be:\nMethsC:\017UserString\"\000"
    end

    ruby_version_is "1.9" do
      it "dumps a US-ASCII String" do
        Marshal.dump("".encode("us-ascii")).should == "\x04\bI\"\x00\x06:\x06EF"
      end

      it "dumps a UTF-8 String" do
        Marshal.dump("".encode("utf-8")).should == "\x04\bI\"\x00\x06:\x06ET"
      end

      it "dumps a String in another encoding" do
        Marshal.dump("".encode("utf-16le")).should == "\x04\bI\"\x00\x06:\rencoding\"\rUTF-16LE"
      end

      it "dumps multiple strings using symlinks for the :E (encoding) symbol" do
        Marshal.dump(["".encode("us-ascii"), "".encode("utf-8")]).should == "\x04\b[\aI\"\x00\x06:\x06EFI\"\x00\x06;\x00T"
      end
    end
  end

  describe "with a Regexp" do
    ruby_version_is ""..."1.9" do
      it "dumps a Regexp" do
        Marshal.dump(/\A.\Z/).should == "\004\b/\n\\A.\\Z\000"
      end

      it "dumps a Regexp with flags" do
        Marshal.dump(//im).should == "\x04\b/\000\005"
      end

      it "dumps a Regexp with instance variables" do
        o = //
        o.instance_variable_set(:@ivar, :ivar)
        Marshal.dump(o).should == "\004\bI/\000\000\006:\n@ivar:\tivar"
      end

      it "dumps an extended Regexp" do
        Marshal.dump(//.extend(Meths)).should == "\004\be:\nMeths/\000\000"
      end

      it "dumps a Regexp subclass" do
        Marshal.dump(UserRegexp.new("")).should == "\004\bC:\017UserRegexp/\000\000"
      end
    end

    ruby_version_is "1.9" do
      it "dumps a Regexp" do
        Marshal.dump(/\A.\Z/).should == "\x04\bI/\n\\A.\\Z\x00\x06:\x06EF"
      end

      it "dumps a Regexp with flags" do
        Marshal.dump(//im).should == "\x04\bI/\x00\x05\x06:\x06EF"
      end

      it "dumps a Regexp with instance variables" do
        o = //
        o.instance_variable_set(:@ivar, :ivar)
        Marshal.dump(o).should == "\x04\bI/\x00\x00\a:\x06EF:\n@ivar:\tivar"
      end

      it "dumps an extended Regexp" do
        Marshal.dump(//.extend(Meths)).should == "\x04\bIe:\nMeths/\x00\x00\x06:\x06EF"
      end

      it "dumps a Regexp subclass" do
        Marshal.dump(UserRegexp.new("")).should == "\x04\bIC:\x0FUserRegexp/\x00\x00\x06:\x06EF"
      end

      it "dumps a binary Regexp" do
        o = Regexp.new(encode("", "binary"), Regexp::FIXEDENCODING)
        Marshal.dump(o).should == "\x04\b/\x00\x10"
      end

      it "dumps a UTF-8 Regexp" do
        o = Regexp.new(encode("", "utf-8"), Regexp::FIXEDENCODING)
        Marshal.dump(o).should == "\x04\bI/\x00\x10\x06:\x06ET"
      end

      it "dumps a Regexp in another encoding" do
        o = Regexp.new(encode("", "utf-16le"), Regexp::FIXEDENCODING)
        Marshal.dump(o).should == "\x04\bI/\x00\x10\x06:\rencoding\"\rUTF-16LE"
      end
    end
  end

  describe "with an Array" do
    it "dumps an empty Array" do
      Marshal.dump([]).should == "\004\b[\000"
    end

    it "dumps a non-empty Array" do
      Marshal.dump([:a, 1, 2]).should == "\004\b[\b:\006ai\006i\a"
    end

    it "dumps an Array subclass" do
      Marshal.dump(UserArray.new).should == "\004\bC:\016UserArray[\000"
    end

    it "dumps a recursive Array" do
      a = []
      a << a
      Marshal.dump(a).should == "\x04\b[\x06@\x00"
    end

    it "dumps an Array with instance variables" do
      a = []
      a.instance_variable_set(:@ivar, 1)
      Marshal.dump(a).should == "\004\bI[\000\006:\n@ivari\006"
    end

    it "dumps an extended Array" do
      Marshal.dump([].extend(Meths)).should == "\004\be:\nMeths[\000"
    end
  end

  describe "with a Hash" do
    it "dumps a Hash" do
      Marshal.dump({}).should == "\004\b{\000"
    end

    it "dumps a Hash subclass" do
      Marshal.dump(UserHash.new).should == "\004\bC:\rUserHash{\000"
    end

    it "dumps a Hash with a default value" do
      Marshal.dump(Hash.new(1)).should == "\004\b}\000i\006"
    end

    it "raises a TypeError with hash having default proc" do
      lambda { Marshal.dump(Hash.new {}) }.should raise_error(TypeError)
    end

    it "dumps a Hash with instance variables" do
      a = {}
      a.instance_variable_set(:@ivar, 1)
      Marshal.dump(a).should == "\004\bI{\000\006:\n@ivari\006"
    end

    it "dumps an extended Hash" do
      Marshal.dump({}.extend(Meths)).should == "\004\be:\nMeths{\000"
    end

    it "dumps an Hash subclass with a parameter to initialize" do
      Marshal.dump(UserHashInitParams.new(1)).should == "\004\bIC:\027UserHashInitParams{\000\006:\a@ai\006"
    end
  end

  describe "with a Struct" do
    it "dumps a Struct" do
      Marshal.dump(Struct::Pyramid.new).should == "\004\bS:\024Struct::Pyramid\000"
    end

    it "dumps a Struct" do
      Marshal.dump(Struct::Useful.new(1, 2)).should == "\004\bS:\023Struct::Useful\a:\006ai\006:\006bi\a"
    end

    it "dumps a Struct with instance variables" do
      st = Struct.new("Thick").new
      st.instance_variable_set(:@ivar, 1)
      Marshal.dump(st).should == "\004\bIS:\022Struct::Thick\000\006:\n@ivari\006"
    end

    it "dumps an extended Struct" do
      st = Struct.new("Extended", :a, :b).new
      Marshal.dump(st.extend(Meths)).should == "\004\be:\nMethsS:\025Struct::Extended\a:\006a0:\006b0"
    end
  end

  describe "with an Object" do
    it "dumps an Object" do
      Marshal.dump(Object.new).should == "\004\bo:\x0BObject\x00"
    end

    it "dumps an extended Object" do
      Marshal.dump(Object.new.extend(Meths)).should == "\004\be:\x0AMethso:\x0BObject\x00"
    end

    it "dumps an Object with an instance variable" do
      obj = Object.new
      obj.instance_variable_set(:@ivar, 1)
      Marshal.dump(obj).should == "\004\bo:\vObject\006:\n@ivari\006"
    end

    it "dumps an Object that has had an instance variable added and removed as though it was never set" do
      obj = Object.new
      obj.instance_variable_set(:@ivar, 1)
      obj.send(:remove_instance_variable, :@ivar)
      Marshal.dump(obj).should == "\004\bo:\x0BObject\x00"
    end

    ruby_version_is "1.9" do
      it "dumps a BasicObject subclass if it defines respond_to?" do
        obj = MarshalSpec::BasicObjectSubWithRespondToFalse.new
        Marshal.dump(obj).should == "\x04\bo:2MarshalSpec::BasicObjectSubWithRespondToFalse\x00"
      end
    end
  end

  describe "with a Range" do
    it "dumps a Range inclusive of end (with indeterminant order)" do
      dump = Marshal.dump(1..2)
      load = Marshal.load(dump)
      load.should == (1..2)
    end

    it "dumps a Range exclusive of end (with indeterminant order)" do
      dump = Marshal.dump(1...2)
      load = Marshal.load(dump)
      load.should == (1...2)
    end
  end

  it "dumps subsequent appearances of a symbol as a link" do
    Marshal.dump([:a, :a]).should == "\004\b[\a:\006a;\000"
  end

  it "dumps subsequent appearances of an object as a link" do
    o = Object.new
    Marshal.dump([o, o]).should == "\004\b[\ao:\vObject\000@\006"
  end

  ruby_version_is "1.9" do
    MarshalSpec::DATA_19.each do |description, (object, marshal, attributes)|
      it "#{description} returns a binary string" do
        Marshal.dump(object).encoding.should == Encoding::BINARY
      end
    end
  end

  it "raises an ArgumentError when the recursion limit is exceeded" do
    h = {'one' => {'two' => {'three' => 0}}}
    lambda { Marshal.dump(h, 3) }.should raise_error(ArgumentError)
    lambda { Marshal.dump([h], 4) }.should raise_error(ArgumentError)
    lambda { Marshal.dump([], 0) }.should raise_error(ArgumentError)
    lambda { Marshal.dump([[[]]], 1) }.should raise_error(ArgumentError)
  end

  it "ignores the recursion limit if the limit is negative" do
    Marshal.dump([], -1).should == "\004\b[\000"
    Marshal.dump([[]], -1).should == "\004\b[\006[\000"
    Marshal.dump([[[]]], -1).should == "\004\b[\006[\006[\000"
  end

  it "writes the serialized data to the IO-Object" do
    (obj = mock('test')).should_receive(:write).at_least(1)
    Marshal.dump("test", obj)
  end

  it "returns the IO-Object" do
    (obj = mock('test')).should_receive(:write).at_least(1)
    Marshal.dump("test", obj).should == obj
  end

  it "raises an Error when the IO-Object does not respond to #write" do
    obj = mock('test')
    lambda { Marshal.dump("test", obj) }.should raise_error(TypeError)
  end

  it "raises a TypeError if marshalling a Method instance" do
    lambda { Marshal.dump(Marshal.method(:dump)) }.should raise_error(TypeError)
  end

  it "raises a TypeError if marshalling a Proc" do
    lambda { Marshal.dump(proc {}) }.should raise_error(TypeError)
  end

  it "raises a TypeError if dumping a IO/File instance" do
    lambda { Marshal.dump(STDIN) }.should raise_error(TypeError)
    lambda { File.open(__FILE__) { |f| Marshal.dump(f) } }.should raise_error(TypeError)
  end

  it "raises a TypeError if dumping a MatchData instance" do
    lambda { Marshal.dump /(.)/.match("foo") }.should raise_error(TypeError)
  end

  it "returns an untainted string if object is untainted" do
    Marshal.dump(Object.new).tainted?.should be_false
  end

  it "returns a tainted string if object is tainted" do
    Marshal.dump(Object.new.taint).tainted?.should be_true
  end

  it "returns a tainted string if nested object is tainted" do
    Marshal.dump([[Object.new.taint]]).tainted?.should be_true
  end

  ruby_version_is "1.9" do
    it "returns a trusted string if object is trusted" do
      Marshal.dump(Object.new).untrusted?.should be_false
    end

    it "returns an untrusted string if object is untrusted" do
      Marshal.dump(Object.new.untrust).untrusted?.should be_true
    end

    it "returns an untrusted string if nested object is untrusted" do
      Marshal.dump([[Object.new.untrust]]).untrusted?.should be_true
    end
  end
end
