class MetadataManagerController < ApplicationController
  
	def properties
    if !params[:token]
      authorize('properties')
    end
    
    @token = params[:token]
	end

	def popsugar
    if !params[:token]
      authorize('popsugar')
    end
    
    @token = params[:token]
	end
  
	def success
    @token = params[:token]
	end
  
  def receive_authorization
    options = { body: { grant_type: 'authorization_code', client_id: 'fhxg60c3x2msvv38d6gjwoimh7igeuzs', client_secret: 'cvvY0WU7iFTJg0RMlXtmFHJbNvINck8f', code: params[:code] } }
	  response = HTTParty.post('https://app.box.com/api/oauth2/token', options)
    parsed_response = JSON.parse(response.body)
    
    redirect_to action: params[:state], token: parsed_response['access_token']
  end

  private
  def authorize(action)
    redirect_to "https://app.box.com/api/oauth2/authorize?response_type=code&client_id=fhxg60c3x2msvv38d6gjwoimh7igeuzs&state=#{action}"
  end
end
