class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home

  def home
  end

  def dashboard
    @user = current_user
    @my_personas = current_user.personas.order(created_at: :desc)
    # Personas créés par les autres utilisateurs (ceux de l'utilisateur sont déjà dans "My personas")
    @available_personas = Persona.where.not(user: current_user).order(:name)
  end
end
