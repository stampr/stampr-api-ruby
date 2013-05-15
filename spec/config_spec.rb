require_relative "spec_helper"

describe Stampr::Config do
  let(:client) { Stampr::Client.new "user", "pass" }
  let(:subject) { described_class.new client }


  describe "initialize(client)" do
    it "should have client set" do
      subject.client.should eq client
    end

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

    it "should fail without a client object" do
      -> { described_class.new 123 }.should raise_error TypeError, "client must be a Stampr::Client"
    end
  end

  describe "initialize(client, data)" do
    let(:data) { JSON.parse(json_data("config")) }
    let(:subject) { described_class.new client, data }

    it "should have client set" do
      subject.client.should eq client
    end

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

    it "should fail without a client object" do
      -> { described_class.new 123 }.should raise_error TypeError, "client must be a Stampr::Client"
    end
  end

  describe "create" do
    it "should do something" do
      stub = stub_request(:post, "https://user:pass@testing.dev.stam.pr/api/configs").
         with(body: {"output"=>"single", "returnenvelope"=>"false", "size"=>"standard", "style"=>"color", "turnaround"=>"threeday"},
              headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'80', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: json_data("config"), headers: {})

      subject.create

      stub.should have_been_made

      subject.id.should eq 4677
    end
  end
end
