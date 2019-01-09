class Cosmos::VotingPowerHistoryDecorator
  include FormattingHelper

  def initialize( validator )
    @validator = validator
  end

  def as_json
    return [] if @validator.voting_power_history.empty?

    data = @validator.voting_power_history.reverse.map do |vph|
      {
        t: vph.block.timestamp.iso8601,
        h: vph.block.height,
        y: vph.data['to']
      }
    end

    data << { t: Time.now.utc.iso8601, y: data.last[:y] }

    first = data.first
    data.unshift( t: Time.parse( first[:t] ).utc.beginning_of_day.iso8601, y: 0 )

    data
  end
end
