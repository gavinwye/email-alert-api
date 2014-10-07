class NotifySubscriberLists
  def initialize(gov_delivery_client:, responder:, subject:, body:, subscriber_lists:)
    @gov_delivery_client = gov_delivery_client
    @subscriber_lists = subscriber_lists
    @subject = subject
    @body = body
    @responder = responder
  end

  def call
    notify_subscriber_lists

    responder.accepted({})
  end

private
  attr_reader(
    :gov_delivery_client,
    :subject,
    :body,
    :subscriber_lists,
    :responder
  )

  def gov_delivery_topic_ids
    subscriber_lists.map(&:gov_delivery_id)
  end

  def notify_subscriber_lists
    gov_delivery_client.send_bulletin(
      gov_delivery_topic_ids,
      subject,
      body,
    )
  end
end
