require_relative "spec_helper"

describe Stampr do
  describe "#initialize" do
    it "should create a rest-client" do
      RestClient::Resource.should_receive("new").with("https://testing.dev.stam.pr/api", "user", "pass")
      Stampr.authenticate "user", "pass"
    end
  end

  describe "#mail" do
    it "should delegate to the current client's #mail" do
      new_mailing = mock Stampr::Mailing
      Stampr.authenticate "user", "pass"
      Stampr.client.should_receive(:mail).with("from", "to", "body", {}).and_return(new_mailing)
      mailing = Stampr.mail "from", "to", "body"
      mailing.should eq new_mailing
    end
  end
end