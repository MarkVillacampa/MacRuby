require File.expand_path('../../fixtures/classes', __FILE__)

# This group of specs may ONLY contain specs that do successfully create
# an IO instance from the file descriptor returned by #new_fd helper.
describe :io_new, :shared => true do
  before :each do
    @name = tmp("io_new.txt")
    @fd = new_fd @name
  end

  after :each do
    if @io and !@io.closed?
      @io.close
    elsif @fd
      IO.new(@fd, "w").close
    end
    rm_r @name
  end

  it "creates an IO instance from a Fixnum argument" do
    @io = IO.send(@method, @fd, "w")
    @io.should be_an_instance_of(IO)
  end

  it "calls #to_int on an object to convert to a Fixnum" do
    obj = mock("file descriptor")
    obj.should_receive(:to_int).and_return(@fd)
    @io = IO.send(@method, obj, "w")
    @io.should be_an_instance_of(IO)
  end

  ruby_version_is "1.9" do
    it "accepts a :mode option" do
      @io = IO.send(@method, @fd, :mode => "w")
      @io.write("foo").should == 3
    end

    it "accepts a mode argument set to nil with a valid :mode option" do
      @io = IO.send(@method, @fd, nil, :mode => "w")
      @io.write("foo").should == 3
    end

    it "accepts a mode argument with a :mode option set to nil" do
      @io = IO.send(@method, @fd, "w", :mode => nil)
      @io.write("foo").should == 3
    end

    it "raises an error if passed modes two ways" do
      lambda {
        IO.send(@method, @fd, "w", :mode => "w")
      }.should raise_error(ArgumentError)
    end

    it "uses the external encoding specified in the mode argument" do
      @io = IO.send(@method, @fd, 'w:utf-8')
      @io.external_encoding.to_s.should == 'UTF-8'
    end

    it "uses the external and the internal encoding specified in the mode argument" do
      @io = IO.send(@method, @fd, 'w:utf-8:ISO-8859-1')
      @io.external_encoding.to_s.should == 'UTF-8'
      @io.internal_encoding.to_s.should == 'ISO-8859-1'
    end

    it "uses the external encoding specified via the :external_encoding option" do
      @io = IO.send(@method, @fd, 'w', {:external_encoding => 'utf-8'})
      @io.external_encoding.to_s.should == 'UTF-8'
    end

    it "uses the internal encoding specified via the :internal_encoding option" do
      @io = IO.send(@method, @fd, 'w', {:internal_encoding => 'iso-8859-1'})
      @io.internal_encoding.to_s.should == 'ISO-8859-1'
    end

    it "uses the colon-separated encodings specified via the :encoding option" do
      @io = IO.send(@method, @fd, 'w', {:encoding => 'utf-8:ISO-8859-1'})
      @io.external_encoding.to_s.should == 'UTF-8'
      @io.internal_encoding.to_s.should == 'ISO-8859-1'
    end

    it "ingores the :encoding option when the :external_encoding option is present" do
      @io = IO.send(@method, @fd, 'w', {:external_encoding => 'utf-8', :encoding => 'iso-8859-1:iso-8859-1'})
      @io.external_encoding.to_s.should == 'UTF-8'
    end

    it "ingores the :encoding option when the :internal_encoding option is present" do
      @io = IO.send(@method, @fd, 'w', {:internal_encoding => 'iso-8859-1', :encoding => 'iso-8859-1:iso-8859-1'})
      @io.internal_encoding.to_s.should == 'ISO-8859-1'
    end

    it "uses the encoding specified via the :mode option hash" do
      @io = IO.send(@method, @fd, {:mode => 'w:utf-8:ISO-8859-1'})
      @io.external_encoding.to_s.should == 'UTF-8'
      @io.internal_encoding.to_s.should == 'ISO-8859-1'
    end

    it "ignores the :internal_encoding option when the same as the external encoding" do
      @io = IO.send(@method, @fd, 'w', {:external_encoding => 'utf-8', :internal_encoding => 'utf-8'})
      @io.external_encoding.to_s.should == 'UTF-8'
      @io.internal_encoding.to_s.should == ''
    end

    it "sets internal encoding to nil when passed '-'" do
      @io = IO.send(@method, @fd, 'w', {:external_encoding => 'utf-8', :internal_encoding => '-'})
      @io.external_encoding.to_s.should == 'UTF-8'
      @io.internal_encoding.to_s.should == ''
    end

    it "raises an error if passed encodings two ways" do
      lambda {
        @io = IO.send(@method, @fd, 'w:ISO-8859-1', {:encoding => 'ISO-8859-1'})
      }.should raise_error(ArgumentError)
      lambda {
        @io = IO.send(@method, @fd, 'w:ISO-8859-1', {:external_encoding => 'ISO-8859-1'})
      }.should raise_error(ArgumentError)
      lambda {
        @io = IO.send(@method, @fd, 'w:ISO-8859-1:UTF-8', {:internal_encoding => 'ISO-8859-1'})
      }.should raise_error(ArgumentError)
    end

    it "sets binmode from mode string" do
      @io = IO.send(@method, @fd, 'wb')
      @io.binmode?.should == true
    end

    it "does not set binmode without being asked" do
      @io = IO.send(@method, @fd, 'w')
      @io.binmode?.should == false
    end

    it "sets binmode from :binmode option" do
      @io = IO.send(@method, @fd, 'w', {:binmode => true})
      @io.binmode?.should == true
    end

    it "does not set binmode from false :binmode" do
      @io = IO.send(@method, @fd, 'w', {:binmode => false})
      @io.binmode?.should == false
    end

    ruby_bug "#5918", "2.0" do
      it "raises an error if passed binary/text mode two ways" do
        ["wb", "wt"].each do |mode|
          [:binmode, :textmode].each do |key|
            [true, false].each do |value|
              lambda {
                @io = IO.send(@method, @fd, mode, key => value)
              }.should raise_error(ArgumentError)
            end
          end
        end
      end
    end

    it "raises an error when trying to set both binmode and textmode" do
      lambda {
        @io = IO.send(@method, @fd, "w", :textmode => true, :binmode => true)
      }.should raise_error(ArgumentError)
      lambda {
        @io = IO.send(@method, @fd, File::Constants::WRONLY, :textmode => true, :binmode => true)
      }.should raise_error(ArgumentError)
    end

    it "sets external encoding to binary with binmode in mode string" do
      @io = IO.send(@method, @fd, 'wb')
      @io.external_encoding.to_s.should == 'ASCII-8BIT'
    end

    ruby_bug "#5917", "2.0" do
      it "sets external encoding to binary with :binmode option" do
        @io = IO.send(@method, @fd, 'w', {:binmode => true})
        @io.external_encoding.to_s.should == 'ASCII-8BIT'
      end
    end

    it "does not use binary encoding when mode encoding is specified" do
      @io = IO.send(@method, @fd, 'wb:iso-8859-1')
      @io.external_encoding.to_s.should == 'ISO-8859-1'
    end

    it "does not use binary encoding when :encoding option is specified" do
      @io = IO.send(@method, @fd, 'wb', :encoding => "iso-8859-1")
      @io.external_encoding.to_s.should == 'ISO-8859-1'
    end

    it "does not use binary encoding when :external_encoding option is specified" do
      @io = IO.send(@method, @fd, 'wb', :external_encoding => "iso-8859-1")
      @io.external_encoding.to_s.should == 'ISO-8859-1'
    end

    it "does not use binary encoding when :internal_encoding option is specified" do
      @io = IO.send(@method, @fd, 'wb', :internal_encoding => "iso-8859-1")
      @io.internal_encoding.to_s.should == 'ISO-8859-1'
    end

    ruby_version_is "1.9.3" do
      it "accepts nil options" do
        @io = IO.send(@method, @fd, 'w', nil)
        @io.write("foo").should == 3
      end
    end

    it "coerces mode with #to_str" do
      mode = mock("mode")
      mode.should_receive(:to_str).any_number_of_times.and_return('w')
      @io = IO.send(@method, @fd, mode)
    end

    it "coerces mode with #to_int" do
      mode = mock("mode")
      mode.should_receive(:to_int).any_number_of_times.and_return(File::WRONLY)
      @io = IO.send(@method, @fd, mode)
    end

    it "coerces mode with #to_str when passed in options" do
      mode = mock("mode")
      mode.should_receive(:to_str).any_number_of_times.and_return('w')
      @io = IO.send(@method, @fd, :mode => mode)
    end

    ruby_version_is "1.9.3" do
      it "coerces mode with #to_int when passed in options" do
        mode = mock("mode")
        mode.should_receive(:to_int).any_number_of_times.and_return(File::WRONLY)
        @io = IO.send(@method, @fd, :mode => mode)
      end
    end

    it "coerces :encoding option with #to_str" do
      encoding = mock("encoding")
      encoding.should_receive(:to_str).any_number_of_times.and_return('utf-8')
      @io = IO.send(@method, @fd, 'w', :encoding => encoding)
    end

    it "coerces :external_encoding option with #to_str" do
      encoding = mock("encoding")
      encoding.should_receive(:to_str).any_number_of_times.and_return('utf-8')
      @io = IO.send(@method, @fd, 'w', :external_encoding => encoding)
    end

    it "coerces :internal_encoding option with #to_str" do
      encoding = mock("encoding")
      encoding.should_receive(:to_str).any_number_of_times.and_return('utf-8')
      @io = IO.send(@method, @fd, 'w', :internal_encoding => encoding)
    end

    it "coerces options as third argument with #to_hash" do
      options = mock("options")
      options.should_receive(:to_hash).any_number_of_times.and_return({})
      @io = IO.send(@method, @fd, 'w', options)
    end

    it "coerces options as second argument with #to_hash" do
      options = mock("options")
      options.should_receive(:to_hash).any_number_of_times.and_return({})
      @io = IO.send(@method, @fd, options)
    end

    it "raises ArgumentError if not passed a hash or nil for options" do
      lambda {
        @io = IO.send(@method, @fd, 'w', false)
      }.should raise_error(ArgumentError)
      lambda {
        @io = IO.send(@method, @fd, false, false)
      }.should raise_error(ArgumentError)
      lambda {
        @io = IO.send(@method, @fd, nil, false)
      }.should raise_error(ArgumentError)
    end

    ruby_version_is "1.9.3" do
      it "raises TypeError if passed a hash for mode and nil for options" do
        lambda {
          @io = IO.send(@method, @fd, {:mode => 'w'}, nil)
        }.should raise_error(TypeError)
      end
    end
  end

  ruby_version_is "1.9.2" do
    it "accepts an :autoclose option" do
      @io = IO.send(@method, @fd, 'w', :autoclose => false)
      @io.autoclose?.should == false
      @io.autoclose = true
    end

    it "accepts any truthy option :autoclose" do
      @io = IO.send(@method, @fd, 'w', :autoclose => 42)
      @io.autoclose?.should == true
    end
  end
end

# This group of specs may ONLY contain specs that do not actually create
# an IO instance from the file descriptor returned by #new_fd helper.
describe :io_new_errors, :shared => true do
  before :each do
    @name = tmp("io_new.txt")
    @fd = new_fd @name
  end

  after :each do
    IO.new(@fd, "w").close
    rm_r @name
  end

  it "raises an Errno::EBADF if the file descriptor is not valid" do
    lambda { IO.send(@method, -1, "w") }.should raise_error(Errno::EBADF)
  end

  it "raises an IOError if passed a closed stream" do
    lambda { IO.send(@method, IOSpecs.closed_io.fileno, 'w') }.should raise_error(IOError)
  end

  it "raises an Errno::EINVAL if the new mode is not compatible with the descriptor's current mode" do
    lambda { IO.send(@method, @fd, "r") }.should raise_error(Errno::EINVAL)
  end

  it "raises ArgumentError if passed an empty mode string" do
    lambda { IO.send(@method, @fd, "") }.should raise_error(ArgumentError)
  end
end
