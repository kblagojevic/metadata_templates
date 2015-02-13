require 'ruby-box'
require 'httparty'
require 'spawn'

#amount of keys allowed per submission
$key_count = 10


class JobManagerController < ApplicationController


	def home

	end

	def new
		
		#Add key items to dictionary. This holds everything needed for the job
		#in memory, It consists of the access token, folder id, template type, and 
		#a hash of the keys and values
		job = Hash.new

		#add box access token and folder ID and the template name
		job["token"] = params[:token]
		job["folder_id"] = params[:folder_id]
		job["template"] = params[:template]

		#if this is for the properties bucket, then run this method
		if job["template"] == "properties"
			#keys and values added to the job dictionary
			i = 0
			
			while i <= $key_count	

				#add items from form to a dictionary
				job["key_#{i}"] = params["key_#{i}"]
				job["value_#{i}"] = params["value_#{i}"]
				
				i +=1

			end 

			#create metadata using dictionary
			Spawn.new do 
				create_metadata(job)
			end
		#if template is not properties and is a custom template, 
		#run different method 
		else
			#loop through each template attribute and store the values in a hash 
			#arranged by attribute
			templateValues = []

			params[:attributes].each do |key, value|
				attributes = Hash.new
				#make sure you only send keys that have an existing value
				if !value.blank?
					attributes["#{key}"] = value
					templateValues.push attributes
				end

			end

			job["templateValues"] = templateValues

			logger.debug "hash being sent is #{job.inspect}"

			create_metadata(job)

		end

		redirect_to success_path

	end

	def get_files(job)

		#get the folder_id you want to iterate
		folder_id = job["folder_id"]

		#get the files from teh folder_id
		file_ids = Array.new
		file_ids =get_files_for_folder(job, folder_id)

		return file_ids

	end
 					
	

	def get_files_for_folder(job, folder_id)

		#set up 


		box_token = "Bearer #{job["token"]}"

		response = HTTParty.get("https://api.box.com/2.0/folders/#{folder_id}/items?limit=1000",
 					:headers => { "Authorization" => box_token})

		#get all files within the specified folder. 
		items = response.parsed_response["entries"]
		file_ids = Array.new
		items.each do |item|
			
			#if item is a file, add it to the array
			if item["type"] == "file"
				file_ids.push(item["id"])
			end

			#if item is a folder, call this same method to iterate through a folder
			if item["type"] == "folder"
				nested_file_ids = Array.new
				nested_file_ids = get_files_for_folder(job, item["id"])
				file_ids = file_ids + nested_file_ids
			end
		end	

		return file_ids

	end


	def create_metadata(job)
 		

 		#get file ids
 		file_ids = get_files(job)
 		
 		logger.debug "job in create metadata is #{job.inspect}"

 		#if template is properties, then you need to create a key:value hash
 		if job["template"] == "properties"
 		
	 		#add keys to a hash if they exist
	 		keys = Hash.new

	 		i=0
	 		while i <= $key_count
		 		#if key exists, add it to a string
		 		if !job["key_#{i}"].blank?
		 			key_field = job["key_#{i}"]

		 			#if the value is blank, add the key with a empty value
		 			if job["value_#{i}"].blank?
		 				keys["#{key_field}"] = ""
					#if the value is not blank, add the value to the key
					else
						keys["#{key_field}"] = job["value_#{i}"]
					end
				end

				i +=1
			end

			#define the scope and type for properties type
			scope = "global"
			type = job["template"]
		
		#if not the properties type, then define custom scope and type and keys hash	
		else
			#add keys to a hash if they exist
	 		keys = Hash.new

	 		#add keys and values to new hash
	 		job["templateValues"].each do |f|
	 		 	hash = Hash.new
	 		 	hash = f
	 		 	hash.each do |key, value|
					keys["#{key}"] = value
				end
	 		end


	 		#keys["editorial"] = job["editorial"]
	 		#keys["imageType"] = job["imageType"]
	 		
	 		#define the scope and type if it's not the properties type
	 		scope = "enterprise"
	 		type = job["template"]

		end

		logger.debug "keys are #{keys.to_json} and type is #{type}"


 		#initialize box headers
 		box_token = "Bearer #{job["token"]}"

 		#add metadata keys for each file
 		file_ids.each do |f| 

 			#create thread of each file
 			Spawn.new do 
 				logger.debug "Spawning on file id #{f}"
 			

	 			response = HTTParty.post("https://api.box.com/2.0/files/#{f}/metadata/#{scope}/#{type}",
	 					:headers => { "Authorization" => box_token, "Content-Type" => "application/json"},
	 					:body => keys.to_json)

	 			logger.debug "response from api is #{response.inspect}"
	 			
	 			#if the properties object exists, perform an update. This will only be additive; if the keys exist
	 			#already, it will not allow them to be added
	 			if response.code == 409

	 				#get existing values first so you know what NOT to overwrite
	 				response = HTTParty.get("https://api.box.com/2.0/files/#{f}/metadata/#{scope}/#{type}",
	 					:headers => { "Authorization" => box_token, "Content-Type" => "application/json"})
	 				parsed_response = JSON.parse(response.body)
	 				
	 				#add existing keys to an array to check for duplicates
	 				existing_keys = Array.new
	 				parsed_response.each do |key,value|
	 					existing_keys.push(key)
					end
					logger.debug "existing keys are #{existing_keys}"

					#add only new keys to updated patch by checking against existing keys
	 				patch = Array.new
	 				
	 				#only add additive keys if properties bucket
	 				if type == "properties"	
		 				keys.each do |key,value|
		 					if !existing_keys.include? key
		 							patch.push({ 'op' => 'add', 'path' => "/#{key}", 'value' => "#{value}"})
		 					end
		 				end
		 			#additive keys don't matter for non properties
		 			else 
		 				keys.each do |key,value|
		 					patch.push({ 'op' => 'add', 'path' => "/#{key}", 'value' => "#{value}"})
		 				end
		 			end
	 				
	 				#send array of patches as a metadata update
	 				json_patch = patch.to_json
	 				logger.debug "json patch for update is #{json_patch}"
	 				response = HTTParty.put("https://api.box.com/2.0/files/#{f}/metadata/#{scope}/#{type}",
	 					:headers => { "Authorization" => box_token, "Content-Type" => "application/json-patch+json"},
	 					:body => json_patch)
	 			end
	 		end

 		end

	end



	 ###function to create client for box ruby sdk - not currently used
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
