module ChainHelper

  def sort_chains( chains )
    chains.sort_by { |c| c.primary? ? 1.minute.from_now : (c.last_sync_time || Time.at(1)) }.reverse
  end

  def chain_header_tooltip_info
    logs_path = cosmos_chain_logs_path(@chain)
    sync_time = @chain.last_sync_time ? "#{distance_of_time_in_words(Time.now, @chain.last_sync_time, true, highest_measures: 2)} ago" : 'Never'

    # TODO: move this to constants somewhere or something
    sync_interval = 2

    [
      "<p><label class='text-muted'>Last synced:</label> #{sync_time}</p>",
      "<p><label class='text-muted'>Sync interval:</label> #{sync_interval} sync/minute</p>",
      "<div class='buttons'>",
        "<a class='btn btn-sm btn-outline-primary' href='#{logs_path}'>View Log</a>",
      "</div>"
    ].join('')
  end

  def chain_voting_power_online_percentage( current, total )
    return 'Cannot calculate %' if total.zero?
    ((current.to_f / total.to_f) * 100).round(0).to_s + '%'
  end

end
