class AccountsController < ApplicationController

  skip_before_filter :require_user, :only => [:new]
  layout :wich_layout
 

  def new
    unless current_subdomain
      @account = Account.new
      @account.users.build
    else
      redirect_to application_root_url(:subdomain => current_subdomain)
    end
  end

  def edit
    @account = Account.find(current_account)
  end

  def create
    @account = Account.new(params[:account])
    @account.subdomain.downcase!
    if @account.save
      flash.now[:notice] = "Hemos enviado la información para ingresar a su email."
      redirect_to application_root_url(:subdomain => @account.subdomain)
    else
      render :action => :new
    end
  end

  def update
    @account = Account.find(current_account)
    if @account.update_attributes(params[:account])
      flash[:notice] = "Información actualizada correctamente."
      redirect_to account_path(@account)
    else
      render :action => "edit"
    end
  end

  def show
  end
  
  private
  
  def wich_layout
    if current_account
      "application"
    else
      "public"
    end
  end

end