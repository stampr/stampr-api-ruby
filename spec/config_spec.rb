require_relative "spec_helper"

describe Stampr::Config do
  before :each do
    Stampr.authenticate "user", "pass"
  end

  let(:subject) { described_class.new }


  describe "#initialize" do
    context "defaulted" do
      it "should do have a size" do
        subject.size.should eq :standard
      end

      it "should have a turnaround" do
        subject.turnaround.should eq :threeday
      end

      it "should have a style" do
        subject.style.should eq :color
      end

      it "should have an output" do
        subject.output.should eq :single
      end

      it "should have a return_envelope" do
        subject.return_envelope.should be_false
      end
    end


    it "should yield itself if block is given" do
      yielded = nil
      config = described_class.new do |c|
        yielded = c
      end

      yielded.should eq config
    end


    context "from data" do
      let(:data) { Hash[JSON.parse(json_data("config_create")).map {|k, v| [k.to_sym, v]}] }
      let(:subject) { described_class.new data }

      it "should do have a size" do
        subject.size.should eq :standard
      end

      it "should have a turnaround" do
        subject.turnaround.should eq :threeday
      end

      it "should have a style" do
        subject.style.should eq :color
      end

      it "should have an output" do
        subject.output.should eq :single
      end

      it "should have a return_envelope" do
        subject.return_envelope.should be_false
      end

      it "should have an id" do
        subject.id.should eq 4677
      end
    end
  end

  let(:uncreated) { Stampr::Config.new }
  let(:created) { Stampr::Config.new config_id: 1 }
  
  describe "#style=" do
    it "should set the value" do
      uncreated.style = :color
      uncreated.style.should eq :color
    end

    it "should fail with a bad type" do
      -> { uncreated.style = 12 }.should raise_error(TypeError, "style must be one of :color")
    end

    it "should fail with a bad value" do
      -> { uncreated.style = :fish }.should raise_error(ArgumentError, "style must be one of :color")
    end

    it "should fail if the Config is already created" do
      -> { created.style = "hello" }.should raise_error(Stampr::ReadOnlyError, "can't modify attribute: style")
    end
  end

  describe "#turnaround=" do
    it "should set the value" do
      uncreated.turnaround = :threeday
      uncreated.turnaround.should eq :threeday
    end

    it "should fail with a bad type" do
      -> { uncreated.turnaround = 12 }.should raise_error(TypeError, "turnaround must be one of :threeday")
    end

    it "should fail with a bad value" do
      -> { uncreated.turnaround = :fish }.should raise_error(ArgumentError, "turnaround must be one of :threeday")
    end

    it "should fail if the Config is already created" do
      -> { created.turnaround = "hello" }.should raise_error(Stampr::ReadOnlyError, "can't modify attribute: turnaround")
    end
  end

  describe "#output=" do
    it "should set the value" do
      uncreated.output = :single
      uncreated.output.should eq :single
    end

    it "should fail with a bad type" do
      -> { uncreated.output = 12 }.should raise_error(TypeError, "output must be one of :single")
    end

    it "should fail with a bad value" do
      -> { uncreated.output = :fish }.should raise_error(ArgumentError, "output must be one of :single")
    end

    it "should fail if the Config is already created" do
      -> { created.output = "hello" }.should raise_error(Stampr::ReadOnlyError, "can't modify attribute: output")
    end
  end

  describe "#size=" do
    it "should set the value" do
      uncreated.size = :standard
      uncreated.size.should eq :standard
    end

    it "should fail with a bad type" do
      -> { uncreated.size = 12 }.should raise_error(TypeError, "size must be one of :standard")
    end

    it "should fail with a bad value" do
      -> { uncreated.size = :fish }.should raise_error(ArgumentError, "size must be one of :standard")
    end

    it "should fail if the Config is already created" do
      -> { created.size = "hello" }.should raise_error(Stampr::ReadOnlyError, "can't modify attribute: size")
    end
  end

  describe "#return_envelope=" do
    it "should set the value" do
      uncreated.return_envelope = true
      uncreated.return_envelope.should be_true
    end

    it "should fail with a bad type" do
      -> { uncreated.return_envelope = 12 }.should raise_error(TypeError, "return_envelope must be one of true, false")
    end

    it "should fail if the Config is already created" do
      -> { created.return_envelope = "hello" }.should raise_error(Stampr::ReadOnlyError, "can't modify attribute: return_envelope")
    end
  end


  describe "#create" do
    it "should post a creation request" do
      request = stub_request(:post, "https://user:pass@testing.dev.stam.pr/api/configs").
         with(body: {"output"=>"single", "returnenvelope"=>"false", "size"=>"standard", "style"=>"color", "turnaround"=>"threeday"},
              headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'80', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: json_data("config_create"), headers: {})

      subject.create

      request.should have_been_made

      subject.id.should eq 4677
    end
  end


  describe ".[]" do
    it "should retreive a specific config" do
      request = stub_request(:get, "https://user:pass@testing.dev.stam.pr/api/configs/4677").
         with(headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: json_data("config_index"), headers: {})

      config = Stampr::Config[4677]

      config.id.should eq 4677

      request.should have_been_made
    end

    it "should fail with a negative id" do
      -> { Stampr::Config[-1] }.should raise_error(ArgumentError, "id should be a positive Integer")
    end

    it "should fail with a bad index" do
      -> { Stampr::Config["fred"] }.should raise_error(TypeError, "id should be a positive Integer")
    end

    it "should fail if the config doesn't exist" do
      request = stub_request(:get, "https://user:pass@testing.dev.stam.pr/api/configs/99").
         with(headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: "[]", headers: {})
         
      -> { Stampr::Config[99] }.should raise_error(Stampr::RequestError, "No such config: 99")
    end
  end


  describe ".all" do
    it "should get a list of all configs" do
      requests = [0, 1, 2].map do |i|
        stub_request(:get, "https://user:pass@testing.dev.stam.pr/api/configs/browse/all/#{i}").
           with(headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
           to_return(status: 200, body: json_data("configs_#{i}"), headers: {})
      end

      configs_ids = Stampr::Config.all.map &:id
      configs_ids.should eq [4677, 4678, 4679]

      requests.each {|request| request.should have_been_made }
    end
  end
end
