class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: "Welcome back."
    else
      redirect_to new_session_path, alert: "Invalid email or password."
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Logged out."
  end
end
