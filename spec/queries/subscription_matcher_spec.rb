require "rails_helper"

RSpec.describe SubscriptionMatcher do
  let(:content_change) do
    create(:notification, tags: { topics: ["oil-and-gas/licensing"] })
  end

  let(:subscribable) do
    create(:subscriber_list, tags: { topics: ["oil-and-gas/licensing"] })
  end

  subject { described_class.call(content_change: content_change) }

  describe ".call" do
    context "with a subscription" do
      before do
        create(:subscription, subscriber_list: subscribable)
      end

      it "returns the subscriptions" do
        expect(subject.count).to eq(1)
      end
    end

    context "with two subscriptions" do
      before do
        create(:subscription, subscriber_list: subscribable)
        create(:subscription, subscriber_list: subscribable, subscriber: create(:subscriber, address: "test2@example.com"))
      end

      it "returns the subscriptions" do
        expect(subject.count).to eq(2)
      end
    end

    context "with no subscriptions" do
      before do
        create(:subscription)
      end

      it "returns no subscriptions" do
        expect(subject.count).to eq(0)
      end
    end
  end
end
