require_relative "spec_helper"

describe Stampr::Client do
  describe "initialize" do
    it "should create a rest-client" do
      RestClient::Resource.should_receive("new").with("https://testing.dev.stam.pr/api", "user", "pass")
      
      described_class.new "user", "pass"
    end
  end
end