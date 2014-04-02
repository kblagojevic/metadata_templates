require 'ruby-box'
require 'httparty'
require 'spawn'


class JobManagerController < ApplicationController


	def new

		#add items from form to a dictionary
		job = Hash.new
		job["token"] = params[:token]
		job["folder_id"] = params[:folder_id]
		job["key_1"] = params[:key_1]
		job["key_2"] = params[:key_2]
		job["key_3"] = params[:key_3]
		job["key_4"] = params[:key_4]
		job["value_1"] = params[:value_1]
		job["value_2"] = params[:value_2]
		job["value_3"] = params[:value_3]
		job["value_4"] = params[:value_4]

		
		#create a client session for the box api and store in dictionary
		client = create_ruby_client(job["token"])
		job["client"] = client

		#create metadata using dictionary
		create_metadata(job)

		redirect_to success_path

	end

	def get_files_for_folder(job)

		client = job["client"]
		box_token = "Bearer #{job["token"]}"

		response = HTTParty.get("https://api.box.com/2.0/folders/#{job["folder_id"]}/items",
 					:headers => { "Authorization" => box_token})

		#get all files within the specified folder
		items = response.parsed_response["entries"]
		file_ids = Array.new
		items.each do |item|
			if item["type"] == "file"
				file_ids.push(item["id"])
			end
		end	

		return file_ids
 					
	end


	def create_metadata(job)
 		
 	

 		#get file ids
 		file_ids = get_files_for_folder(job)
 		

 		#add keys to a hash if they exist
 		keys = Hash.new
 		if !job["key_1"].blank?
 			key_1 = job["key_1"]
 			if job["value_1"].blank?
 				keys["#{key_1}"] = ""
 			else
 				keys["#{key_1}"] = job["value_1"]
 			end
 		end

 		if !job["key_2"].blank?
 			key_2 = job["key_2"]
 			if job["value_2"].blank?
 				keys["#{key_2}"] = ""
 			else
 				keys["#{key_2}"] = job["value_2"]
 			end
 		end

 		if !job["key_3"].blank?
 			key_3 = job["key_3"]
 			if job["value_3"].blank?
 				keys["#{key_3}"] = ""
 			else
 				keys["#{key_3}"] = job["value_3"]
 			end
 		end

 		if !job["key_4"].blank?
 			key_4 = job["key_4"]
 			if job["value_4"].blank?
 				keys["#{key_4}"] = ""
 			else
 				keys["#{key_4}"] = job["value_4"]
 			end
 		end

 		#initialize box headers
 		client = job["client"]
 		box_token = "Bearer #{job["token"]}"

 		###add metadata keys for each file
 		file_ids.each do |f| 
 			response = HTTParty.post("https://api.box.com/2.0/files/#{f}/metadata/properties",
 					:headers => { "Authorization" => box_token, "Content-Type" => "application/json"},
 					:body => keys.to_json)
 			logger.debug "response is #{response.inspect}"
 			
 			#if the properties object exists, perform an update. This will only be additive; if the keys exist
 			#already, it will not allow them to be added
 			if response.code == 409

 				patch = Array.new
 				#keys.each_key do |key|
 				keys.each do |key,value|
 					patch.push({ 'op' => 'add', 'path' => "/#{key}", 'value' => "#{value}"})
 				end
 				json_patch = patch.to_json

 				response = HTTParty.put("https://api.box.com/2.0/files/#{f}/metadata/properties",
 					:headers => { "Authorization" => box_token, "Content-Type" => "application/json-patch+json"},
 					:body => json_patch)
 					logger.debug "response is #{response.inspect}"
 			end

 		end

	end



	 #function to create client for box ruby sdk
  def create_ruby_client(token)
    
    #initialize session with ruby gem
    session = RubyBox::Session.new({
      access_token: token.to_s,
      client_id: 'bu19jq5tl4xg61d2tvcuq7dl7a4tsgqj',
      client_secret: 'FvlNZ8Yn8O4eDSVFLPor6IO7Z2zXvT3X'
      })

    #create and return ruby client
    client = RubyBox::Client.new(session)
	end
    
end
