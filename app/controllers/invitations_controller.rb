class InvitationsController < ApplicationController
  # Le propriétaire comme les membres peuvent inviter quelqu'un, par son pseudo
  def create
    chat = Chat.accessible_by(current_user).find(params[:chat_id])
    invitee = User.find_by(username: params[:username].to_s.strip)
    return redirect_to(chat, alert: "No member named \"#{params[:username].to_s.strip}\".") unless invitee

    invitation = new_invitation(chat, invitee)
    return redirect_to(chat, alert: "#{invitee.username} is already invited.") unless invitation

    if invitation.save
      redirect_to chat, notice: "Invitation sent to #{invitee.username}."
    else
      redirect_to chat, alert: invitation.errors.full_messages.to_sentence
    end
  end

  def accept
    invitation = current_user.received_invitations.pending.find(params[:id])
    invitation.update!(status: "accepted")
    redirect_to chat_path(invitation.chat), notice: "You joined the conversation."
  end

  def decline
    current_user.received_invitations.pending.find(params[:id]).update!(status: "declined")
    redirect_to dashboard_path, notice: "Invitation declined."
  end

  private

  # Invitation à enregistrer, ou nil si la personne est déjà invitée (en attente) ou déjà membre.
  # Une invitation refusée est réutilisée : l'index unique (chat, invité) interdit d'en créer une deuxième.
  def new_invitation(chat, invitee)
    invitation = chat.invitations.find_or_initialize_by(invitee: invitee)
    return if invitation.persisted? && !invitation.declined?

    invitation.assign_attributes(inviter: current_user, status: "pending")
    invitation
  end
end
