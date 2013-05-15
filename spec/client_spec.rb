require_relative "spec_helper"

describe Stampr::Client do
  before :each do
    Stampr.authenticate "user", "pass"
  end

  describe "initialize" do
    it "should create a rest-client" do
      RestClient::Resource.should_receive("new").with("https://testing.dev.stam.pr/api", "user", "pass")
      Stampr.authenticate "user", "pass"
    end
  end

  describe "ping" do
    it "should do something" do
      pending #p subject.ping
    end
  end
end