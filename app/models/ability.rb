class Ability
  include CanCan::Ability

  def initialize(user_info)

    if !user_info # guest user (not logged in)
      can :read, Survey do |survey|
        nil
      end
      can :build, Survey if Rails.env.test? # Couldn't log in a user from Capybara
    else
      role = user_info[:role]
      if role == 'admin'
        can :manage, :all # TODO: Verify this
      elsif role == 'cso_admin'
        can :read, Survey, :organization_id => user_info[:org_id]
        can :read, Survey, :participating_organizations => { :organization_id => user_info[:org_id] }
        can :build, Survey, :organization_id => user_info[:org_id]
        can :create, Survey
        can :publish, Survey, :organization_id => user_info[:org_id]
        can :edit, Survey, :organization_id => user_info[:org_id]
        can :share, Survey, :organization_id => user_info[:org_id]
        can :destroy, Survey, :organization_id => user_info[:org_id]

        can :create, Response, :survey => { :organization_id => user_info[:org_id] }
        can :read, Response, :survey => { :organization_id => user_info[:org_id] } 
      elsif role == 'user'
        can :read, Survey, :survey_users => { :user_id => user_info[:user_id ] }
        can :create, Response, :survey => { :survey_users => { :user_id => user_info[:user_id ] } }
        can :read, Response, :user_id  => user_info[:user_id]
      end
    end
  end
end