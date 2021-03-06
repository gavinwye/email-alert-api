RSpec.describe DigestRunSubscriber do
  describe ".populate" do
    let(:digest_run) { create(:digest_run) }

    it "inserts digest run subscribers" do
      subscribers = create_list(:subscriber, 2)
      expect { described_class.populate(digest_run, subscribers.map(&:id)) }
        .to change { described_class.count }.by(2)
    end

    it "sets the appropriate attributes" do
      freeze_time do
        subscriber = create(:subscriber)
        described_class.populate(digest_run, [subscriber.id])
        expect(described_class.last).to have_attributes(
          digest_run_id: digest_run.id,
          subscriber_id: subscriber.id,
          created_at: Time.zone.now,
          updated_at: Time.zone.now,
        )
      end
    end

    it "returns an array of ids" do
      subscriber = create(:subscriber)
      ids = described_class.populate(digest_run, [subscriber.id])
      expect(ids).to eq([described_class.last.id])
    end

    it "raises an error when given an empty collection of subscribers" do
      expect { described_class.populate(digest_run, []) }
        .to raise_error(ArgumentError)
    end
  end

  describe ".unprocessed_for_run" do
    it "returns records with the supplied digest_run_id that have processed_at of nil" do
      create(:digest_run, id: 1)
      digest_run_subscriber = create(
        :digest_run_subscriber,
        digest_run_id: 1,
        processed_at: nil,
      )

      expect(described_class.unprocessed_for_run(1).first).to eq(digest_run_subscriber)
    end

    it "doesn't return processed items" do
      create(:digest_run, id: 1)
      create(
        :digest_run_subscriber,
        digest_run_id: 1,
        processed_at: Time.zone.now,
      )

      expect(described_class.unprocessed_for_run(1).count).to eq(0)
    end

    it "doesn't return records from other runs" do
      create(:digest_run, id: 2)
      create(
        :digest_run_subscriber,
        digest_run_id: 2,
        processed_at: nil,
      )

      expect(described_class.unprocessed_for_run(1).count).to eq(0)
    end
  end
end
