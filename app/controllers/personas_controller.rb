class PersonasController < ApplicationController
  before_action :set_persona, only: [ :edit, :update, :destroy]

  def index
    @personas = Persona.all
  end

  def show
    @persona = Persona.find(params[:id])
  end

  def new
    @persona = Persona.new
  end

  def create
    @persona = current_user.personas.new(persona_params)
    if @persona.save
      redirect_to @persona, notice: "Persona created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @persona.update(persona_params)
      redirect_to @persona, notice: "Persona mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @persona.destroy
    redirect_to personas_path, notice: "Persona supprimée.", status: :see_other
  end

  private

  def set_persona
    @persona = current_user.personas.find(params[:id])
  end

  def persona_params
    params.require(:persona).permit(:name, :description, :system_prompt, :avatar_url)
  end
end
