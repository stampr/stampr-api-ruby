require_relative "spec_helper"

describe Stampr::Mailing do
  before :each do
    Stampr.authenticate "user", "pass"
  end

  let(:mailing_create) { Hash[JSON.parse(json_data("mailing_create")).map {|k, v| [k.to_sym, v]}] }


  describe "#initialize" do
    it "should generate a Batch if it isn't included" do
      Stampr::Batch.should_receive(:new).with().and_return(mock(id: 7))
      subject = described_class.new
      subject.batch_id.should eq 7
    end

    it "should fail with batch & batch_id" do
      ->{ described_class.new batch_id: 2, batch: mock }.should raise_error(ArgumentError, "Must supply :batch_id OR :batch options")
    end

    it "should fail with bad data" do
      ->{ described_class.new batch_id: 2, data: 12 }.should raise_error(TypeError, "Bad format for data")
    end

    it "should yield itself then mail itself if block is given" do
      yielded = nil
      mailing = described_class.new batch_id: 1 do |m|
        m.should_receive(:mail).with()
        yielded = m
      end
      yielded.should be_a Stampr::Mailing
      yielded.should eq mailing
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
         with(body: {"batch_id"=>"2", "address" => "bleh1", "returnaddress" => "bleh2", "format" => "json", "data" => Base64.encode64(data.to_json) },
              headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'91', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: json_data("mailing_create"), headers: {})

      subject.mail
      subject.id.should eq 1

      request.should have_been_made
    end

    it "should post a mailing request with html data" do
      data = "<html>Hello world!</html>"
      subject = described_class.new batch_id: 2, address: "bleh1", returnaddress: "bleh2", data: data

      request = stub_request(:post, "https://user:pass@testing.dev.stam.pr/api/mailings").
         with(body: {"batch_id"=>"2", "address" => "bleh1", "returnaddress" => "bleh2", "format" => "html", "data" => Base64.encode64(data) },
              headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'107', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: json_data("mailing_create"), headers: {})

      subject.mail
      subject.id.should eq 1

      request.should have_been_made
    end

    it "should post a mailing with pdf data" do
      data = "%PDF1.4..."
      subject = described_class.new batch_id: 2, address: "bleh1", returnaddress: "bleh2", data: data

      request = stub_request(:post, "https://user:pass@testing.dev.stam.pr/api/mailings").
         with(body: {"batch_id"=>"2", "address" => "bleh1", "returnaddress" => "bleh2", "format" => "pdf", "data" => Base64.encode64(data) },
              headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'84', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: json_data("mailing_create"), headers: {})

      subject.mail
      subject.id.should eq 1

      request.should have_been_made
    end

    it "should fail without an address" do
      data = "%PDF1.4..."
      subject = described_class.new batch_id: 2, returnaddress: "bleh"

      -> { subject.mail }.should raise_error Stampr::APIError, "address required before mailing"
    end

    it "should fail without a return address" do
      data = "%PDF1.4..."
      subject = described_class.new batch_id: 2, address: "bleh"

      -> { subject.mail }.should raise_error Stampr::APIError, "return_address required before mailing"
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