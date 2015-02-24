class MetadataManagerController < ApplicationController
  
	def properties
    if !cookies[:box_token]
      authorize('properties')
    end
    
    @token = cookies[:box_token]
	end

	def popsugar
    # refresh the token if there's less than five mins left before expiry
    if cookies[:token_expiry] && cookies[:token_expiry].to_i < Time.now().to_i - 300 
      refresh_token
    # refresh token expires after 60 days and we need to re-auth
    elsif cookies[:token_expiry].to_i < Time.now().to_i - 5184300
      authorize('popsugar')
    end
    
    @token = cookies[:box_token]
	end
  
	def success
    @token = cookies[:box_token]
	end
  
  def receive_authorization
    options = { body: { grant_type: 'authorization_code', client_id: 'fhxg60c3x2msvv38d6gjwoimh7igeuzs', client_secret: 'cvvY0WU7iFTJg0RMlXtmFHJbNvINck8f', code: params[:code] } }
	  response = HTTParty.post('https://app.box.com/api/oauth2/token', options)
    parsed_response = JSON.parse(response.body)

    cookies[:box_token] = parsed_response['access_token']
    cookies[:refresh_token] = parsed_response['refresh_token']
    cookies[:token_expiry] = Time.now().to_i + parsed_response['expires_in'].to_i
    
    redirect_to action: params[:state]
  end

  private
  def authorize(action)
    redirect_to "https://app.box.com/api/oauth2/authorize?response_type=code&client_id=fhxg60c3x2msvv38d6gjwoimh7igeuzs&state=#{action}"
  end
  
  def refresh_token
    options = { body: { grant_type: 'refresh_token', client_id: 'fhxg60c3x2msvv38d6gjwoimh7igeuzs', client_secret: 'cvvY0WU7iFTJg0RMlXtmFHJbNvINck8f', refresh_token: cookies[:refresh_token] } }
    response = HTTParty.post('https://app.box.com/api/oauth2/token', options)
    parsed_response = JSON.parse(response.body)

    cookies[:box_token] = parsed_response['access_token']
    cookies[:refresh_token] = parsed_response['refresh_token']
    cookies[:token_expiry] = Time.now().to_i + parsed_response['expires_in'].to_i
  end
end
