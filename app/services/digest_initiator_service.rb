class DigestInitiatorService
  def initialize(range:)
    @range = range
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    digest_run = create_digest_run
    return if digest_run.nil?

    subscribers = DigestRunSubscriberQuery.call(digest_run: digest_run)

    digest_run_subscriber_params = build_digest_run_subscriber_params(
      digest_run,
      subscribers
    )

    digest_run_subscriber_ids = import_digest_run_subscribers(
      digest_run_subscriber_params
    )

    enqueue_jobs(digest_run_subscriber_ids)
  end

private

  attr_reader :range

  def create_digest_run
    run_with_advisory_lock do
      digest_run = DigestRun.find_or_initialize_by(
        date: Date.current, range: range
      )
      return if digest_run.persisted?
      digest_run.save!
      digest_run
    end
  end

  def build_digest_run_subscriber_params(digest_run, subscribers)
    subscribers.map do |subscriber|
      {
        subscriber_id: subscriber.id,
        digest_run_id: digest_run.id
      }
    end
  end

  def enqueue_jobs(digest_run_subscriber_ids)
    Array(digest_run_subscriber_ids).each do |digest_run_subscriber_id|
      DigestEmailGenerationWorker.perform_async(digest_run_subscriber_id)
    end
  end

  def run_with_advisory_lock
    DigestRun.with_advisory_lock(lock_name, timeout_seconds: 0) do
      yield
    end
  end

  def lock_name
    "#{range}_digest_initiator"
  end

  def import_digest_run_subscribers(params)
    DigestRunSubscriber.import!(params).ids
  end
end