class Common::Event < ApplicationRecord
  belongs_to :chainlike, polymorphic: true
  belongs_to :validatorlike, polymorphic: true, optional: true
  belongs_to :transactionlike, polymorphic: true, optional: true
  belongs_to :accountlike, polymorphic: true, optional: true
  belongs_to :proposallike, polymorphic: true, optional: true
  belongs_to :votelike, polymorphic: true, optional: true
  
  after_create :tweet_maybe
  validates_uniqueness_of :transactionlike_id

  def kind_string
    self.class.name.demodulize.underscore
  end

  def block
    chainlike.blocks.find_by( height: height ) ||
    chainlike.class.name.deconstantize.constantize::Block.stub( chainlike, height )
  end

  def to_partial_path
    self.class.name.underscore
  end

  private

  def tweet_maybe
    return if !chainlike.has_twitter_config?

    begin
      r = Router.new
      msg = "#{twitter_msg} - #{r.namespaced_path( 'event', id: id, type: type, chain: chainlike, full: true )}"

      tc = chainlike.twitter_events_config
      client = Twitter::REST::Client.new do |config|
        config.consumer_key = tc['consumer_key']
        config.consumer_secret = tc['consumer_secret']
        config.access_token = tc['access_token']
        config.access_token_secret = tc['access_secret']
      end

      if Rails.env.production?
        client.update( msg )
      else
        puts "\n############ TWEET ############\n#{msg}\n\n"
      end
    rescue
      Rollbar.error($!, "Could not tweet validator event #{self.id}")
    end
  end
end