class ResponseController < ApplicationController
before_filter :prepare_request
protect_from_forgery :except => [:interpret_command]

require 'open-uri'

	def interpret_command
		case @command
			when "weather"
				get_weather			
			when "score"
				get_scores
			when "hi"
				say_hi
			else
				@final_results = "Command " + @command.upcase + " not found."
		end

		twilio_message(@final_results)
		render :xml => @message.to_xml( :root => 'Response' )		
	end

	private

		def parse_message
			message = @incoming_body.split(' ', 3);

			all_sub_commands = [ "today", "tomorrow", "tmrw", "tom", "forecast", "4cast" ]

			if all_sub_commands.include? message[1].downcase
				@sub_command = message[1]
				@location = message[2]
			else
				message = @incoming_body.split(' ', 2)
				@location = message[1]
			end

		end

		def get_weather
			parse_message

			weather_api_url = 'http://www.google.com/ig/api?weather=' + URI.escape(@location)
			doc = Nokogiri::HTML(open(weather_api_url))

			info_element = doc.search('forecast_information').first
			
			timestamp = Time.parse(
				info_element.search('current_date_time').first[:data]
			).strftime('%-1I:%M%p %Z')

			city = info_element.search('city').first[:data]

			case @sub_command
				when "today"
					# forecast_conditions[0]
					element = doc.search('forecast_conditions').first
					temp = element.search('high').first[:data]
					condition = element.search('condition').first[:data]
					@final_results = "Today: " + condition + " and " + temp + " in " + city
				when "tomorrow", "tmrw", "tom"
					# forecast_conditions[1]
					element = doc.search('forecast_conditions')[1]
					temp = element.search('high').first[:data]
					condition = element.search('condition').first[:data]					
					@final_results = element.search('day_of_week').first[:data] + ": " + condition + " and " + temp + " in " + city					
				when "forecast","4cast"
					# forecast_conditions, looping
					count = 0
					@running_forecast = ''
					doc.search('forecast_conditions').each do |element|
						count = count + 1
						if count < 4
							day = element.search('day_of_week').first[:data]
							high = element.search('high').first[:data]
							low = element.search('low').first[:data]
							condition = element.search('condition').first[:data]
							todays_forecast = day + ": " + high + "/" + low
							@running_forecast = @running_forecast + todays_forecast + " "
						end
					end
					@final_results = city + ": " + @running_forecast
				else
					# sub_command not found
					# current weather
					element = doc.search('current_conditions')
					temp = element.search('temp_f').first[:data]
					condition = element.search('condition').first[:data]					
					@final_results = "Currently " + condition.downcase + " and " + temp + " in " + city + " at " + timestamp
			end

		end

		def get_scores
			@final_results = "scores stuff"
		end

		def say_hi
			@final_results = "hi!"
		end

		def twilio_message(msg)
			@message = { 'Sms' => msg }
		end

		def prepare_request
			accessible_params = [ "Body", "From", "FromCity", "FromCountry", "FromState", "FromZip" ]

			params.each do |param|
				if accessible_params.include? param[0]
					key = param[0].downcase
					value = param[1]
					eval("@incoming_#{key} = value")
				end
			end

			@command = @incoming_body.split(' ')[0]
		end

end