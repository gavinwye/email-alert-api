RSpec.describe "Subscriptions auth token", type: :request do
  include TokenHelpers

  before { login_with_internal_app }

  describe "creating an auth token" do
    let(:path) { "/subscriptions/auth-token" }
    let(:address) { "test@example.com" }
    let(:topic_id) { "business-tax-corporation-tax" }
    let(:frequency) { "daily" }
    let(:params) do
      {
        address: address,
        topic_id: topic_id,
        frequency: frequency,
      }
    end

    it "returns 200" do
      post path, params: params
      expect(response.status).to eq(200)
    end

    context "when we're provided with no email address" do
      let(:address) { nil }

      it "returns a 422" do
        post path, params: params
        expect(response.status).to eq(422)
      end
    end
    context "when we're provided with a badly formatted email address" do
      let(:address) { "wrong.bad" }

      it "returns a 422" do
        post path, params: params
        expect(response.status).to eq(422)
      end
    end
    context "when we're provided with no topic_id" do
      let(:topic_id) { nil }

      it "returns a 422" do
        post path, params: params
        expect(response.status).to eq(422)
      end
    end
    context "when we're provided with no frequency" do
      let(:frequency) { nil }

      it "returns a 422" do
        post path, params: params
        expect(response.status).to eq(422)
      end
    end
    context "when we're provided with a bad frequency" do
      let(:frequency) { "something_else" }

      it "returns a 422" do
        post path, params: params
        expect(response.status).to eq(422)
      end
    end

    it "creates an email" do
      expect { post path, params: params }.to change { Email.count }.by(1)
    end

    it "sends the email" do
      expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)
      post path, params: params
    end

    it "sends an email with the correct token" do
      post path, params: params
      expect(Email.count).to be 1
      token = Email.last.body.match(/token=([^&)]+)/)[1]
      expect(decrypt_and_verify_token(token)).to eq(
        "address" => address,
        "topic_id" => topic_id,
        "frequency" => frequency,
      )
    end
  end
end
