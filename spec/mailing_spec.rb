require_relative "spec_helper"

describe Stampr::Mailing do
  before :each do
    Stampr.authenticate "user", "pass"
  end

  let(:mailing_create) { Hash[JSON.parse(json_data("mailing_create")).map {|k, v| [k.to_sym, v]}] }


  describe "#initialize" do
    it "should fail with bad data" do
      ->{ described_class.new batch_id: 2, address: "bleh1", returnaddress: "bleh2", data: 12 }.
          should raise_error(TypeError, "Bad format for data")
    end
  end

  describe "#mail" do
    it "should post a mailing request without data" do
      subject = described_class.new batch_id: 2, address: "bleh1", returnaddress: "bleh2"

      request = stub_request(:post, "https://user:pass@testing.dev.stam.pr/api/mailings").
         with(body: {"batch_id"=>"2", "address" => "bleh1", "returnaddress" => "bleh2", "format"=>"none"},
              headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'56', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: json_data("mailing_create"), headers: {})

      subject.mail
      subject.id.should eq 1

      request.should have_been_made
    end

    it "should post a mailing request with json data" do
      data = {"fred" => "savage"}
      subject = described_class.new batch_id: 2, address: "bleh1", returnaddress: "bleh2", data: data

      request = stub_request(:post, "https://user:pass@testing.dev.stam.pr/api/mailings").
         with(body: {"batch_id"=>"2", "address" => "bleh1", "returnaddress" => "bleh2", "format" => "json", "data" => data.to_json},
              headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'93', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: json_data("mailing_create"), headers: {})

      subject.mail
      subject.id.should eq 1

      request.should have_been_made
    end

    it "should post a mailing request with html data" do
      data = "<html>Hello world!</html>"
      subject = described_class.new batch_id: 2, address: "bleh1", returnaddress: "bleh2", data: data

      request = stub_request(:post, "https://user:pass@testing.dev.stam.pr/api/mailings").
         with(body: {"batch_id"=>"2", "address" => "bleh1", "returnaddress" => "bleh2", "format" => "html", "data" => data},
              headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'99', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: json_data("mailing_create"), headers: {})

      subject.mail
      subject.id.should eq 1

      request.should have_been_made
    end

    it "should post a mailing with pdf data" do
      data = "%PDF1.4..."
      subject = described_class.new batch_id: 2, address: "bleh1", returnaddress: "bleh2", data: data

      request = stub_request(:post, "https://user:pass@testing.dev.stam.pr/api/mailings").
         with(body: {"batch_id"=>"2", "address" => "bleh1", "returnaddress" => "bleh2", "format" => "pdf", "data" => data},
              headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'73', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: json_data("mailing_create"), headers: {})

      subject.mail
      subject.id.should eq 1

      request.should have_been_made
    end
  end


  describe "#delete" do
    it "should delete the mailing" do
      subject = described_class.new mailing_create

      request = stub_request(:delete, "https://user:pass@testing.dev.stam.pr/api/mailings/1").
         with(headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: [true].to_json, headers: {})

      subject.delete.should eq true

      request.should have_been_made
    end

    it "should fail if the mailing isn't created yet" do
      subject = described_class.new batch_id: 2

      -> { subject.delete.should eq true }.should raise_error Stampr::APIError, "Can't #delete before #create"
    end
  end


  describe ".[]" do
    it "should retreive a specific mailing" do
      request = stub_request(:get, "https://user:pass@testing.dev.stam.pr/api/mailings/1").
         with(headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: json_data("mailing_index"), headers: {})

      mailing = Stampr::Mailing[1]

      mailing.id.should eq 1

      request.should have_been_made
    end
  end
end