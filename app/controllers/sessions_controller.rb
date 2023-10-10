class SessionsController < ApplicationController
  skip_before_action :connect_to_db, :require_account
  skip_before_action :require_user, only: %i(new create destroy callback)
  skip_before_action :verify_authenticity_token, only: %i(create)

  def new; end

  def create
    user = User.find_by(email: params[:session][:email])

    if user
      get_options = relying_party.options_for_authentication(
        allow: user.credentials.pluck(:external_id),
        user_verification: "required"
      )

      session[:current_authentication] = { challenge: get_options.challenge, email: user.email }

      respond_to do |format|
        format.json { render json: get_options }
      end
    else
      respond_to do |format|
        format.json { render json: { error: "User doesn't exist." }, status: :unprocessable_entity }
      end
    end
  end

  def callback
    user = User.find_by(email: session["current_authentication"]["email"])
    raise "user #{session["current_authentication"]["email"]} never initiated sign up" unless user

    begin
      verified_webauthn_credential, stored_credential = relying_party.verify_authentication(
        params,
        session["current_authentication"]["challenge"],
        user_verification: true,
      ) do |webauthn_credential|
        user.credentials.find_by(external_id: Base64.strict_encode64(webauthn_credential.raw_id))
      end

      stored_credential.update!(sign_count: verified_webauthn_credential.sign_count)
      session[:user_id] = user.id
      collaborator = user.collaborators.first
      if collaborator
        session[:collaborator_id] = collaborator.id
        session[:account_id] = collaborator.account_id
      end

      render json: { status: "ok" }, status: :ok
    rescue WebAuthn::Error => e
      render json: "Verification failed: #{e.message}", status: :unprocessable_entity
    ensure
      session.delete("current_authentication")
    end
  end

  def switch_account
    collaborator = current_user.collaborators.find_by(account_id: params[:account_id])
    if collaborator&.account
      session[:account_id] = collaborator.account_id
      session[:collaborator_if] = collaborator.id
    end
    redirect_to dashboard_url
  end

  def destroy
    session.clear
    redirect_to root_url, notice: 'Signed out!'
  end
end
