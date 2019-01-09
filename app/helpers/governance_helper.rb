module GovernanceHelper

  def total_deposits_for_proposal( proposal )
    proposal.total_deposits.map do |deposit|
      "#{deposit[:total_amount]} #{deposit[:denom]}"
    end.join('<br />').html_safe
  end

  def deposits_for_proposal_by_account( proposal, account )
    deposits = proposal.deposits.where( account: account )

    if deposits.any?
      grouped = deposits.group_by(&:amount_denom)
      tag.div do
        tag.label( class: 'd-block mb-1 text-muted' ) { 'Deposits:' } +
        grouped.map do |denom, deposits|
          tag.div( class: 'text-nowrap' ) do
            format_amount(deposits.sum(&:amount), proposal.chain, token_denom_override: denom)
          end
        end.join('').html_safe
      end
    end
  end

  def vote_for_proposal_by_account( proposal, account )
    vote = proposal.votes.where( account: account ).last
    if vote
      tag.div( class: 'd-flex align-items-center' ) do
        tag.label( class: 'd-block mt-2 mb-1 mr-2 text-muted' ) { 'Vote:' } +
        tag.span( class: 'badge badge-pill badge-primary' ) { vote.option }
      end
    end
  end

end
