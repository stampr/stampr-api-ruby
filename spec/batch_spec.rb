require_relative "spec_helper"

describe Stampr::Batch do
  before :each do
    Stampr.authenticate "user", "pass"
  end


  describe "#initialize" do
    let(:subject) { described_class.new config_id: 1 }

    it "should do have a size" do
      subject.config_id.should eq 1
    end

    it "should not have a template" do
      subject.template.should be_nil
    end

    it "should have a default status" do
      subject.status.should eq :processing
    end
  end


  describe "#initialize from data" do
    let(:data) { Hash[JSON.parse(json_data("batch_create")).map {|k, v| [k.to_sym, v]}] }
    let(:subject) { described_class.new data }

    it "should do have a size" do
      subject.config_id.should eq 1
    end

    it "should have a template" do
      subject.template.should eq "bleh"
    end

    it "should have a status" do
      subject.status.should eq :processing
    end

    it "should have an id" do
      subject.id.should eq 2
    end
  end


  describe "#create" do
    it "should post a creation request without a template" do
      subject = described_class.new config_id: 1

      request = stub_request(:post, "https://user:pass@testing.dev.stam.pr/api/batches").
         with(body: {"config_id"=>"1", "status"=>"processing"},
              headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'29', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: json_data("batch_create"), headers: {})

      subject.create
      subject.id.should eq 2

      request.should have_been_made
    end

    it "should post a creation request with a template" do
      subject = described_class.new config_id: 1, template: "Bleh"

      request = stub_request(:post, "https://user:pass@testing.dev.stam.pr/api/batches").
         with(body: {"config_id"=>"1", "status"=>"processing", "template"=>"Bleh"},
              headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'43', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: json_data("batch_create"), headers: {})

      subject.create
      subject.id.should eq 2

      request.should have_been_made
    end
  end

  describe "#delete" do
    it "should delete the batch" do
      subject = described_class.new config_id: 1, template: "Bleh", batch_id: 2

      request = stub_request(:delete, "https://user:pass@testing.dev.stam.pr/api/batches/2").
         with(headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: [true].to_json, headers: {})

      subject.delete.should eq true

      request.should have_been_made
    end

    it "should fail if the batch isn't created yet" do
      subject = described_class.new config_id: 1, template: "Bleh"

      -> { subject.delete.should eq true }.should raise_error Stampr::APIError, "Can't #delete before #create"
    end
  end
end