require "rails_helper"

RSpec.describe DataImport do
  subject { DataImport }
  let(:current_time) { Time.new(2023, 1, 15, 11, 30, 0, "-06:00") }
  let(:date) { "2023-1-15".to_date }
  let(:yesterday) { "2023-1-14".to_date }

  describe ".latest_date and .earliest_date" do
    before do
      allow(Time).to receive(:now).and_return(current_time)
    end

    it ".latest_date should be yesterday in central time" do
      expect(subject.latest_date).to eq yesterday
    end

    it ".earliest_date should be DAYS_BACK_WINDOW days ago in central time" do
      expect(subject.earliest_date).to eq(date - subject::DAYS_BACK_WINDOW)
    end
  end

  describe ".days_to_load" do
    context "no successful loads" do
      let(:days) { subject.days_to_load }

      it { expect(days).to be_an Array }
      it { expect(days.first).to be_an Date }

      it "only lists days that are within the defined range" do
        expect(days.min).to be >= subject.earliest_date
      end

      it "returns all dates in window" do
        expect(days.count).to be subject::DAYS_BACK_WINDOW
      end
    end

    context "one successful load" do
      it "returns all other days" do
        dates_to_load = subject.days_to_load
        successful_date = subject.earliest_date
        subject.create(status: "successful", date: successful_date)
        expect(subject.days_to_load).to match_array(dates_to_load - [successful_date])
      end
    end
  end

  describe ".pending" do
    it "returns pending imports" do
      obj = subject.create(status: "pending", date:)
      expect(subject.pending).to eq [obj]
    end
  end

  describe ".started" do
    it "returns started imports" do
      obj = subject.create(status: "started", date:)
      expect(subject.started).to eq [obj]
    end
  end

  describe ".successful" do
    it "returns successful imports" do
      obj = subject.create(status: "successful", date:)
      expect(subject.successful).to eq [obj]
    end
  end

  describe ".failed" do
    it "returns failed imports" do
      obj = subject.create(status: "failed", date:)
      expect(subject.failed).to eq [obj]
    end
  end

  describe ".start" do
    it "creates a new DataImport record" do
      expect { subject.start(date) }.to change(subject, :count).by 1
    end

    it "creates a record with status: started" do
      obj = subject.start(date)
      expect(subject.started).to eq [obj]
    end

    it "updates existing record" do
      obj = subject.create(status: "pending", date:)
      expect(subject.find_by(date:)).to eq obj
      subject.start(date)
      expect(subject.find_by(date:).status).to eq "started"
      expect(subject.where(date:).size).to eq 1
    end

    it "records a message in the record" do
      subject.start(date, "foo")
      expect(subject.started.first.message).to eq "foo"
    end
  end

  describe ".succeed" do
    it "creates a new DataImport record" do
      expect { subject.succeed(date) }.to change(subject, :count).by 1
    end

    it "creates a record with status: successful" do
      obj = subject.succeed(date)
      expect(subject.successful).to eq [obj]
    end

    it "updates existing record" do
      obj = subject.create(status: "successful", date:)
      expect(subject.find_by(date:)).to eq obj
      subject.succeed(date)
      expect(subject.find_by(date:).status).to eq "successful"
      expect(subject.where(date:).size).to eq 1
    end

    it "records a message in the record" do
      subject.succeed(date, "foo")
      expect(subject.successful.first.message).to eq "foo"
    end
  end

  describe ".fail" do
    it "creates a new DataImport record" do
      expect { subject.fail(date) }.to change(subject, :count).by 1
    end

    it "creates a record with status: failed" do
      obj = subject.fail(date)
      expect(subject.failed).to eq [obj]
    end

    it "updates existing record" do
      obj = subject.create(status: "failed", date:)
      expect(subject.find_by(date:)).to eq obj
      subject.fail(date)
      expect(subject.find_by(date:).status).to eq "failed"
      expect(subject.where(date:).size).to eq 1
    end

    it "records a message in the record" do
      subject.fail(date, "foo")
      expect(subject.failed.first.message).to eq "foo"
    end

    it "records a default message in the record" do
      subject.fail(date)
      expect(subject.failed.first.message).to eq "No reason given"
    end
  end

  describe ".create_pending" do
    it "creates a pending record for each import type" do
      subject.create_pending(date)
      expect(subject.pending.size).to eq 6
    end
  end

  describe ".check_statuses" do
    let(:daily_imports) { subject.import_types }

    context "when all statuses successful" do
      before do
        daily_imports.each { |import| import.succeed(date) }
      end

      it "checks all statuses in date range and reports none failed" do
        statuses = subject.check_statuses(date, date)
        expect(statuses).to be_a Hash
        expect(statuses[:count]).to eq 0
      end
    end

    context "when statuses missing" do
      it "creates pending records where none exist" do
        expect { subject.check_statuses(date, date) }.to change(subject, :count).by(daily_imports.size)
      end

      it "checks all statuses in date range and reports the number not successful" do
        statuses = subject.check_statuses(date, date)
        expect(statuses).to be_a Hash
        expect(statuses[:count]).to eq(daily_imports.size)
      end
    end
  end

  describe ".send_status_email" do
    let(:daily_imports) { subject.import_types }
    let(:dates) { subject.earliest_date..subject.latest_date }

    context "when all statuses successful" do
      before do
        dates.each do |date|
          daily_imports.each { |import| import.succeed(date) }
        end
      end

      it "doesn't send an email" do
        expect(StatusMailer).to_not receive(:status_mail)
        subject.send_status_email
      end
    end

    context "when statuses not successful" do
      it "sends an email" do
        expect(StatusMailer).to receive(:status_mail).and_call_original
        subject.send_status_email
      end
    end
  end
end
