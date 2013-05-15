require_relative "spec_helper"

describe Stampr::Client do
  let(:subject) { described_class.new "user", "pass" }

  describe "initialize" do
    it "should create a rest-client" do
      RestClient::Resource.should_receive("new").with("https://testing.dev.stam.pr/api", "user", "pass")
      subject
    end
  end

  describe "ping" do
    it "should do something" do
      pending #p subject.ping
    end
  end
end