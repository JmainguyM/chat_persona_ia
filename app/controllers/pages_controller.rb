class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home

  def home
  end

  def dashboard
    @user = current_user
    # Conversations ayant au moins un message, la plus récente en premier
    @chats = current_user.chats.where.associated(:messages).distinct
                         .includes(:persona, :messages).order(updated_at: :desc)
    @my_personas = current_user.personas.custom.order(created_at: :desc)
    # Personas de base + ceux des autres utilisateurs (ceux de l'utilisateur sont déjà dans "My personas")
    @available_personas = Persona.built_in.or(Persona.where.not(user: current_user)).order(built_in: :desc, name: :asc)
  end
end
