class Stats::SyncLog < ApplicationRecord
  belongs_to :chain, class_name: 'Cosmos::Chain'

  default_scope -> { order('started_at DESC') }
  scope :completed, -> { where( 'completed_at IS NOT NULL' ) }
  scope :failed, -> { where( 'failed_at IS NOT NULL' ) }
  scope :today, -> { where( 'started_at >= ? AND started_at <= ?',
                            Time.now.utc.beginning_of_day, Time.now.utc.end_of_day ) }

  class << self
    def start( chain, start_height )
      create(
        chain: chain,
        started_at: Time.now.utc,
        start_height: start_height
      )
    end
  end

  def timestamp
    ended_at || started_at
  end

  def ended_at
    completed_at || failed_at
  end

  def duration
    ended_at ? (ended_at.to_f - started_at.to_f) : 0
  end

  def end( end_height )
    chain.sync_completed!
    update_attributes(
      completed_at: Time.now.utc,
      start_height: start_height,
      end_height: end_height
    )
  end

  def error( exception )
    chain.sync_failed!
    update_attributes(
      failed_at: Time.now.utc,
      error: "#{$!.message}\n#{$!.backtrace.join("\n")}"
    )
  end
end
