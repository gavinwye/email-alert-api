RSpec.describe UnsubscribeLinkPresenter do
  describe ".call" do
    it "returns a presented unsubscribe link" do
      expected = "[Unsubscribe from ‘Test title’](http://www.dev.gov.uk/email/unsubscribe/abc123)"
      expect(described_class.call("abc123", "Test title")).to eq(expected)
    end
  end
end
