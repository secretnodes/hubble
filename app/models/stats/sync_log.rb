class Stats::SyncLog < ApplicationRecord
  belongs_to :chain, class_name: 'Cosmos::Chain'

  default_scope -> { order('started_at DESC') }
  scope :completed, -> { where( 'completed_at IS NOT NULL' ) }
  scope :failed, -> { where( 'failed_at IS NOT NULL' ) }
  scope :today, -> { where( 'started_at >= ? AND started_at <= ?',
                            Time.now.utc.beginning_of_day, Time.now.utc.end_of_day ) }

  class << self
    def start( chain )
      create(
        chain: chain,
        started_at: Time.now.utc,
        start_height: chain.latest_local_height+1
      )
    end
  end

  def failed?
    !failed_at.nil?
  end
  def success?
    !failed? && !completed_at.nil?
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

  def end
    chain.sync_completed!
    update_attributes(
      completed_at: Time.now.utc,
      start_height: start_height,
      end_height: chain.reload.latest_local_height
    )
  end

  def set_status( status )
    update_attributes( current_status: status )
  end

  def report_error( exception )
    chain.sync_failed!
    critical = exception.is_a?(Cosmos::SyncBase::CriticalError)
    puts "\n\n#{'CRITICAL ' if critical}SYNC ERROR: #{exception.message}"

    bc = ActiveSupport::BacktraceCleaner.new
    bc.add_filter { |line| line.gsub(Rails.root.to_s, '') }
    bc.add_silencer { |line| line.include? "lib/ruby/gems" }
    bc.add_silencer { |line| line.include? "bin/bundle" }
    puts "#{bc.clean(exception.backtrace).join("\n")}\n\n"

    update_attributes(
      end_height: chain.reload.latest_local_height,
      failed_at: Time.now.utc,
      error: [ error, "Failed during #{current_status}: #{exception.message}" ].reject(&:blank?).join( "\n" )
    )
  end
end
