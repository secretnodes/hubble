class CommentsController < ApplicationController
  layout 'none'

  def create
    @comment = Comment.new(comment_params)

    if @comment.save!
      flash[:success] = "You successfully submitted your comment. Thanks for participating in the dicussion!"
      redirect_back(fallback_location: root_path)
    else
      flash[:error] = "There was an error saving your comment. Please try again."
      redirect_back(fallback_location: root_path)
    end
  end

  private

  def comment_params
    params.require(:comment).permit(
      :comment,
      :user_id,
      :commentable_type,
      :commentable_id
    )
  end
end