class CommentChannel < ApplicationCable::Channel
  def subscribed
    stream_from "comment"
  end
end
