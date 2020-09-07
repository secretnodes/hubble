class Common::Events::Deposit < Common::Event
  include FormattingHelper

  def icon_name; 'funnel-dollar'; end

  def positive?; true; end

  def amount
    data['amount'].to_i
  end

  def twitter_msg
    r = Router.new
    "#{accountlike.address} deposited #{format_amount(amount, chainlike, denom: 'uscrt', in_millions: true, html: false)} in support of Proposal #{proposallike.ext_id}: #{proposallike.title}. #{r.namespaced_path( 'governance_proposal', id: proposallike.ext_id, chain: chainlike, full: true )}"
  end

  def page_title
    "#{accountlike.address} deposited #{format_amount(amount, chainlike, denom: 'uscrt', hide_units: true, in_millions: true, html: false)} in support of Proposal #{proposallike.ext_id}: #{proposallike.title}."
  end
end