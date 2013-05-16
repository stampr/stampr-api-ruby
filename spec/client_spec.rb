require_relative "spec_helper"

describe Stampr::Client do
  let(:subject) { Stampr::Client.new "user", "pass" }

  describe "#initialize" do
    it "should create a rest-client" do
      RestClient::Resource.should_receive("new").with("https://testing.dev.stam.pr/api", "user", "pass")
      Stampr::Client.new "user", "pass"
    end
  end

  describe "#ping" do
    it "should do something" do
      sent_at, received_at = Time.parse("2013-05-16 18:02:00 +0100"), Time.parse("2013-05-16 18:02:10 +0100")

      Time.should_receive(:now).with().and_return(sent_at, received_at)

      now = "2013-05-16 18:02:47 +0100"

      request = stub_request(:get, "https://user:pass@testing.dev.stam.pr/api/test/ping").
         with(headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: { "pong" => now }.to_json, headers: {})

      subject.ping.should eq 5.0
    end
  end

  describe "#server_time" do
    it "should do something" do
      time = "2013-05-16 18:02:47 +0100"
      request = stub_request(:get, "https://user:pass@testing.dev.stam.pr/api/test/ping").
         with(headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: { "pong" => time }.to_json, headers: {})

      server_time = subject.server_time
      server_time.should be_a Time
      server_time.to_s.should eq time
    end
  end
end