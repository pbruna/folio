class UserSessionsController < ApplicationController
  layout 'public'

  def new
    if current_subdomain.nil?
      render :action => "new"
    elsif current_account.nil?
      raise ActionController::RoutingError.new('Not Found')
    else
      @user_session = UserSession.new
    end
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      redirect_to application_root_url
    else
      render :action => "new"
    end
  end

  def destroy
    @user_session = UserSession.find
    @user_session.destroy
    redirect_to public_root_url(:subdomain => false)
  end

end
