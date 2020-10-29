class CommentsController < ApplicationController
  layout 'none'
  load_and_authorize_resource
  include CableReady::Broadcaster
  def create
    user = User.find comment_params[:user_id]
    if user.username.blank?
      flash[:error] = "You must set a username in your #{view_context.link_to 'Account Settings', edit_user_registration_path} before commenting.".html_safe
      redirect_back(fallback_location: root_path) and return
    end
    @comment = Comment.new(comment_params)

    if @comment.save!
      cable_ready['comment'].insert_adjacent_html(
        selector: '.comments',
        position: 'beforeend',
        html: render_to_string(partial: '/shared/comments/show', locals: {comment: @comment})
      )
      cable_ready.broadcast
      
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