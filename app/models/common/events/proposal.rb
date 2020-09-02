class Common::Events::Proposal < Common::Event

  def icon_name; 'gavel'; end

  def positive?; true; end

  def name
    transactionlike.message[0]['value']['AmountENG'].to_i
  end

  def twitter_msg
    r = Router.new
    "#{accountlike.address} submitted Proposal #{proposallike.ext_id}: #{proposallike.title}. #{r.namespaced_path( 'governance_proposal', id: proposallike.ext_id, chain: chainlike, full: true )}"
  end

  def page_title
    "#{accountlike.address} submitted Proposal #{proposallike.ext_id}: #{proposallike.title}."
  end
end