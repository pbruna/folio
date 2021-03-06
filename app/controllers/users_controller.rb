class UsersController < ApplicationController
  #before_filter :current_account_admin, :except => [:create, :update, :destroy]
  before_filter :find_user, :only => [:show, :edit, :update]

  def new
    if account_admin?
      @user = User.new
    elsif
      render :template => "/shared/error/404.html.erb", :status => 404, :layout => "error"
    end
  end

  def show
  end

  def edit
    unless account_admin? || @user.id == current_user.id
      render :template => "/shared/error/404.html.erb", :status => 404, :layout => "error"
    end
  end

  def enable
    @user = User.find(params[:id])
    if @user.enable!
      flash[:notice] = "Usuario habilitado."
    else
      flash[:notice] = "No fue posible habilitar el usuario."
    end
    redirect_to account_path(current_account.id)
  end
  
  def disable
    @user = User.find(params[:id])
    if @user.disable!
      flash[:notice] = "Usuario inhabilitado."
    else
      flash[:notice] = "No fue posible inhabilitar el usuario."
    end
    redirect_to account_path(current_account.id)
  end
  

  def create
    @user = User.new(params[:user])
    password = params[:user][:password]
    if @user.save
      @user.send_later(:deliver_welcome_guest_email!, current_user.id, password)
      flash[:notice] = "Usuario creado correctamente."
      redirect_to account_path(current_account.id)
    else
      render :action => 'new'
    end
  end

  def update

    if @user.update_attributes(params[:user])
      flash[:notice] = "Datos actualizados."
      redirect_to edit_user_path(@user)
    else
      render :action => 'edit'
    end
  end

  def destroy
    @user = User.find(params[:id])
    account_id = @user.account_id
    if @user.destroy
      flash[:notice] = "Usuario eliminado"
      redirect_to account_path(account_id)
    else
      flash[:notice] = "No es posible eliminar este usuario."
      redirect_to account_path(account_id)
    end
  end

  private
    def current_account_admin
      if (params[:account_id].to_i == current_account.id) && account_admin?
        return
      else
        render :template => "/shared/error/404.html.erb", :status => 404, :layout => "error"
      end
    end

    def find_user
      @user = User.find(params[:id], :conditions => ["account_id = ?", current_account.id ])
    end

end
