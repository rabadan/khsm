# (c) goodprogrammer.ru
#
# Контроллер, отображающий список и профиль юзера
class UsersController < ApplicationController
  before_action :set_user, only: [:show]

  def index
    @users = User.all.order(balance: :desc)
  end

  def show
    @games = @user.games.order(created_at: :desc)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
