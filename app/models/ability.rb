# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user, controller_namespace = nil)
    user ||= User.new
    if controller_namespace == 'Admin'
      can :manage, :all if user.sudo?
    else
      if user.sudo?
        can :manage, :all
      elsif user.foundation?
        can %i{ edit update }, Secret::Petition, petition_type: :foundation
      elsif user.puzzle_staker?
      elsif !user.new_record?
        can :manage, Secret::Petition, user_id: user.id
        can :manage, Comment, user_id: user.id
        can :manage, Secret::PetitionVote, user_id: user.id
        can :manage, Wallet, user_id: user.id
      end
    end
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  end
end
