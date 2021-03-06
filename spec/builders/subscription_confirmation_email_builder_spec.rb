RSpec.describe SubscriptionConfirmationEmailBuilder do
  describe ".call" do
    let(:subscriber_list) { create(:subscriber_list, title: "Example") }
    let(:subscription) { create(:subscription, subscriber_list: subscriber_list) }

    subject(:call) do
      described_class.call(subscription: subscription)
    end

    it { is_expected.to be_instance_of(Email) }

    it "creates an email" do
      expect { call }.to change(Email, :count).by(1)
    end

    it "includes the title of the subscriber list" do
      title = "Example"
      email = call
      expect(email.subject).to include(title)
      expect(email.body).to include(title)
      expect(email.body).to match(/You’ll get an email each time there are changes to/)
    end

    it "includes a link to manage subscriptions" do
      text = "View, unsubscribe or change the frequency of your subscriptions"
      email = call
      expect(email.body).to include(text)
    end

    context "when the subscriber list has a URL" do
      let(:subscriber_list) { create(:subscriber_list, url: "/example") }

      it "includes a link to the subscriber list" do
        link = "http://www.dev.gov.uk/example?utm_campaign=govuk-notifications-subscription-confirmation&utm_medium=email&utm_source=#{subscriber_list.slug}"
        email = call
        expect(email.body).to include(link)
      end
    end

    context "when the subscriber list has a description" do
      let(:subscriber_list) { create(:subscriber_list, description: "Example description") }

      it "includes the description of the subscriber list" do
        description = "Example description"
        email = call
        expect(email.body).to include(description)
      end
    end
  end
end
