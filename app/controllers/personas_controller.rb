class PersonasController < ApplicationController
  # La liste est publique ; il faut un compte pour chatter ou créer un persona
  skip_before_action :authenticate_user!, only: :index
  before_action :set_persona, only: %i[edit update destroy]

  def index
    # Après login / sign up depuis cette page, Devise ramène ici
    store_location_for(:user, personas_path) unless user_signed_in?

    @built_in_personas = Persona.built_in.order(:name)
    @community_personas = Persona.custom.order(created_at: :desc)
  end

  def new
    @persona = Persona.new
  end

  def create
    @persona = current_user.personas.new(persona_params)
    if @persona.save
      redirect_to dashboard_path(anchor: "my-personas"), notice: "#{@persona.name} is ready to chat."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @persona.update(persona_params)
      redirect_to dashboard_path(anchor: "my-personas"), notice: "#{@persona.name} updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @persona.destroy
    redirect_to dashboard_path(anchor: "my-personas"), notice: "Persona deleted.", status: :see_other
  end

  private

  # Seuls les personas créés par l'utilisateur sont modifiables (jamais les personas de base)
  def set_persona
    @persona = current_user.personas.custom.find(params[:id])
  end

  def persona_params
    params.require(:persona).permit(:name, :description, :system_prompt, :avatar_url)
  end
end
