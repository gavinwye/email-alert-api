class Email < ApplicationRecord
  # Any validations added this to this model won't be applied on record
  # creation as this table is populated by the #insert_all bulk method

  COURTESY_EMAIL = "govuk-email-courtesy-copies@digital.cabinet-office.gov.uk".freeze
  has_many :delivery_attempts

  scope :archivable,
        lambda {
          where(archived_at: nil).where.not(status: :pending)
        }

  scope :deleteable,
        lambda {
          where.not(status: :pending).where("archived_at < ?", 7.days.ago)
        }

  enum status: { pending: 0, sent: 1, failed: 2 }

  # This can be removed once the column is deleted.
  self.ignored_columns = %i[failure_reason]

  def self.timed_bulk_insert(records, batch_size)
    return insert_all!(records) unless records.size == batch_size

    Metrics.email_bulk_insert(batch_size) { insert_all!(records) }
  end
end
