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

    it "should yield itself if block is given" do
      yielded = nil
      batch = described_class.new config_id: 1 do |b|
        yielded = b
      end

      yielded.should eq batch
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
    context "not yet created" do
      let(:subject) { described_class.new config_id: 1 }

      it "should accept a correct symbol" do
        subject.status.should eq :processing # The default.
        subject.status = :hold
        subject.status.should eq :hold
      end

      it "should refuse incorrect symbols" do
        -> { subject.status = :frog }.should raise_error(ArgumentError, "status must be one of: :processing, :hold, :archive")
      end

      it "should refuse other data" do
        -> { subject.status = 14 }.should raise_error(TypeError, "status must be a Symbol")
      end
    end

    context "already created" do
      let(:subject) { described_class.new config_id: 1, batch_id: 2 }

      it "should accept a correct symbol" do
        request = stub_request(:post, "https://user:pass@testing.dev.stam.pr/api/batches/2").
           with(body: {"status"=>"hold"},
                headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'11', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
           to_return(status: 200, body: json_data("batch_create"), headers: {})

        subject.status.should eq :processing
        subject.status = :hold
        subject.status.should eq :hold

        request.should have_been_made
      end

      it "should do nothing if value hasn't changed" do
        subject.status = :processing
        subject.status.should eq :processing
      end
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

      subject.delete.should be_nil

      request.should have_been_made
    end

    it "should fail if the batch isn't created yet" do
      subject = described_class.new config_id: 1, template: "Bleh"

      -> { subject.delete }.should raise_error Stampr::APIError, "Can't #delete before #create"
    end
  end


  describe ".[]" do
    context "with id" do
      it "should retreive a specific batch" do
        request = stub_request(:get, "https://user:pass@testing.dev.stam.pr/api/batches/1").
           with(headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
           to_return(status: 200, body: json_data("batch_index"), headers: {})

        batch = Stampr::Batch[1]

        batch.id.should eq 2

        request.should have_been_made
      end

      it "should fail with a negative id" do
        -> { Stampr::Batch[-1] }.should raise_error(TypeError, "id should be a positive Integer")
      end
    end

    context "with range" do
      [Time, DateTime].each do |period_class|
        it "should retrieve a list over a #{period_class} period" do
          requests = [0, 1, 2].map do |i|
            stub_request(:get, "https://user:pass@testing.dev.stam.pr/api/batches/browse/1900-01-01T00:00:00Z/2000-01-01T00:00:00Z/#{i}").
               with(headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
               to_return(status: 200, body: json_data("batches_#{i}"), headers: {})
          end

          from, to = period_class.new(1900, 1, 1, 0, 0, 0, "+00:00"), period_class.new(2000, 1, 1, 0, 0, 0, "+00:00")
          batches = Stampr::Batch[from..to]

          batches.map(&:id).should eq [2, 3, 4]

          requests.each {|request| request.should have_been_made }
        end
      end

      it "should fail with a bad range" do
        -> { Stampr::Batch[1..3] }.should raise_error(TypeError, "Can only use a range of Time/DateTime")
      end
    end

    context "with range & status" do
      [Time, DateTime].each do |period_class|
        it "should retrieve a list of batches over a #{period_class} period with given status" do
          requests = [0, 1, 2].map do |i|
            stub_request(:get, "https://user:pass@testing.dev.stam.pr/api/batches/with/processing/1900-01-01T00:00:00Z/2000-01-01T00:00:00Z/#{i}").
               with(headers: {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
               to_return(status: 200, body: json_data("batches_#{i}"), headers: {})
          end

          from, to = period_class.new(1900, 1, 1, 0, 0, 0, "+00:00"), period_class.new(2000, 1, 1, 0, 0, 0, "+00:00")
          batches = Stampr::Batch[from..to, status: :processing]

          batches.map(&:id).should eq [2, 3, 4]

          requests.each {|request| request.should have_been_made }
        end
      end

    it "should fail with a bad status" do
        -> { Stampr::Batch[Time.new(1900, 1, 1, 0, 0, 0, "+00:00")..Time.new(2000, 1, 1, 0, 0, 0, "+00:00"), status: 12] }.should raise_error(TypeError, ":status option should be one of :processing, :hold, :archive")
      end
      it "should fail with a bad status" do
        -> { Stampr::Batch[Time.new(1900, 1, 1, 0, 0, 0, "+00:00")..Time.new(2000, 1, 1, 0, 0, 0, "+00:00"), status: :frog] }.should raise_error(ArgumentError, ":status option should be one of :processing, :hold, :archive")
      end

      it "should fail with a bad range" do
        -> { Stampr::Batch[1..3, status: :processing] }.should raise_error(TypeError, "Can only use a range of Time/DateTime")
      end
    end

    it "should fail with a bad index" do
      -> { Stampr::Batch["fred"] }.should raise_error(TypeError, "index must be a positive Integer or Time/DateTime range")
    end
  end


  describe "#mailing" do
    it "should yield a new mailing and mail it" do
      Stampr::Config.should_receive(:new).with().once.and_return(mock(id: 7))

      yielded = nil
      batch = Stampr::Batch.new batch_id: 6, template: "frog"

      mailing = batch.mailing do |m|
        m.should_receive(:mail).with()
        yielded = m
      end

      yielded.should eq mailing
      yielded.should be_a Stampr::Mailing
      yielded.batch_id.should eq 6
    end

    it "should be happy without a block" do
      Stampr::Config.should_receive(:new).with().once.and_return(mock(id: 7))

      batch = Stampr::Batch.new batch_id: 6, template: "frog"

      mail = batch.mailing

      mail.should be_a Stampr::Mailing
      mail.batch_id.should eq 6
    end
  end
end