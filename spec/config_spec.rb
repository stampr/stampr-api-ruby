require_relative "spec_helper"

describe Stampr::Config do
  before :each do
    Stampr.authenticate "user", "pass"
  end

  let(:subject) { described_class.new }


  describe "#initialize" do
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


  describe "#initialize from data" do
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
  end

  describe ".each" do
    it "should yield each config" do
      requests = [0, 1, 2].map do |i|
        stub_request(:get, "https://user:pass@testing.dev.stam.pr/api/configs/all/#{i}").
           with(headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
           to_return(status: 200, body: json_data("configs_#{i}"), headers: {})
      end

      configs_ids = []

      Stampr::Config.each do |config|
        configs_ids << config.id
      end

      configs_ids.should eq [4677, 4678, 4679]

      requests.each {|request| request.should have_been_made }
    end
  end
end
