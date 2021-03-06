class DeliveryRequestService < ApplicationService
  PROVIDERS = {
    "notify" => NotifyProvider,
    "pseudo" => PseudoProvider,
    "delay" => DelayProvider,
  }.freeze

  def initialize(email:, metrics: {})
    config = EmailAlertAPI.config.email_service
    @email = email
    @metrics = metrics
    @attempt_id = SecureRandom.uuid
    @provider_name = config.fetch(:provider).downcase
    @subject_prefix = config.fetch(:email_subject_prefix)
    @overrider = EmailAddressOverrider.new(config)
  end

  def call
    return if address.nil?

    Metrics.delivery_request_service_first_delivery_attempt do
      record_first_attempt_metrics unless DeliveryAttempt.exists?(email: email)
    end

    attempt = Metrics.delivery_request_service_create_delivery_attempt do
      DeliveryAttempt.create!(id: attempt_id,
                              email: email,
                              status: :sending,
                              provider: provider_name)
    end

    status = Metrics.email_send_request(provider_name) { send_email }

    return attempt if status == :sending

    ActiveRecord::Base.transaction do
      attempt.update!(status: status, completed_at: Time.zone.now)
      Metrics.delivery_attempt_status_changed(status)
      email.mark_as_sent(attempt.finished_sending_at) if attempt.delivered?
      email.mark_as_failed(attempt.finished_sending_at) if attempt.undeliverable_failure?
    end

    attempt
  end

private

  attr_reader :attempt_id, :email, :metrics, :provider_name, :subject_prefix, :overrider

  def address
    @address ||= overrider.destination_address(email.address)
  end

  def send_email
    provider = PROVIDERS.fetch(provider_name)

    provider.call(
      address: address,
      subject: subject_prefix + email.subject,
      body: email.body,
      reference: attempt_id,
    )
  rescue StandardError => e
    GovukError.notify(e)
    :provider_communication_failure
  end

  def record_first_attempt_metrics
    now = Time.zone.now.utc
    Metrics.email_created_to_first_delivery_attempt(email.created_at, now)

    return unless metrics[:content_change_created_at]

    Metrics.content_change_created_to_first_delivery_attempt(
      metrics[:content_change_created_at],
      now,
    )
  end
end
