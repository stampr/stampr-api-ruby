require_relative "spec_helper"


describe Stampr::Batch do
  before :each do
    Stampr.authenticate "user", "pass"
  end

  let(:batch_create) { Hash[JSON.parse(json_data("batch_create")).map {|k, v| [k.to_sym, v]}] }

  describe "#initialize" do
    it "should generate a Config if it isn't included" do
      Stampr::Config.should_receive(:new).with().and_return(mock(id: 7))
      subject = described_class.new
      subject.config_id.should eq 7
    end

    it "should fail with config & batch_id" do
      ->{ described_class.new config_id: 2, config: mock }.should raise_error(ArgumentError, "Must supply :config_id OR :config options")
    end

    context "defaulted" do
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


    context "from data" do
      let(:subject) { described_class.new batch_create }

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
  end


  describe "#template=" do
    let(:subject) { described_class.new config_id: 1 }

    it "should accept a string" do
      subject.template = "fish"
      subject.template.should eq "fish"
    end

    it "should accept nil" do
      subject.template = nil
      subject.template.should be_nil
    end

    it "should refuse other data" do
      -> { subject.template = 14 }.should raise_error(TypeError, "template must be a String")
    end
  end


  describe "#status=" do
    let(:subject) { described_class.new config_id: 1 }

    it "should accept a string" do
      subject.status = :archive
      subject.status.should eq :archive
    end

    it "should refuse incorrect symbols" do
      -> { subject.status = :frog }.should raise_error(ArgumentError, "status must be one of: :processing, :hold, :archive")
    end

    it "should refuse other data" do
      -> { subject.status = 14 }.should raise_error(TypeError, "status must be a Symbol")
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


  describe ".[]" do
    it "should retreive a specific batch" do
      request = stub_request(:get, "https://user:pass@testing.dev.stam.pr/api/batches/2").
         with(headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: json_data("batch_index"), headers: {})

      batch = Stampr::Batch[2]

      batch.id.should eq 2

      request.should have_been_made
    end
  end
end