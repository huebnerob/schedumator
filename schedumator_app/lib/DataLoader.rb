require 'net/http'
require 'rexml/document'
require 'pp'

# This class manages the importing of the class XML data into Schedumator rails models

class DataLoader 
	def self.start
		DataLoader.loadLocalXML
		DataLoader.generateSections
	end


	def self.allSupportedTerms
		return ['2014S']
	end

	def self.latestTerm
		return allSupportedTerms[0]
	end

	def self.getURL(term)
		url = "http://www.stevens.edu/scheduler/core/core.php?cmd=getxml&term=#{term}"
	end

	def self.loadLatestXML
		xml_data = Net::HTTP.get_response(URI.parse(DataLoader.getURL DataLoader.latestTerm)).body
		@doc = REXML::Document.new(xml_data)
	end

	def self.loadLocalXML #stores a cached XML on our server in case stevens is offline/malformed
		xml_data = File.read("2013f.xml")
		@doc = REXML::Document.new(xml_data)
	end

	def self.generateSections
		@doc.elements.each 'Semester/Course' do |crs|
			section = crs.attributes["Section"]
			sectionTitle = crs.attributes["Title"]
			# sectionCallNumber = crs.attributes["CallNumber"]
			sectionMeetings = []
			crs.elements.each('Meeting') do |mtg|
				mtgDays = mtg.attributes["Day"]
				mtgStart = mtg.attributes["StartTime"] 
				mtgEnd = mtg.attributes["EndTime"]
				# mtgBuilding = mtg.attributes["Building"]
				# mtgRoom = mtg.attributes["Room"]
				# mtgInfo = mtgBuilding + mtgRoom 
				if mtgStart != nil
					sectionMeetings << [mtgDays, mtgStart, mtgEnd]
				end
			end

			# puts section + " " + sectionTitle + " has " + sectionBlocks.length.to_s + " blocks."
			s = Section.generate sectionMeetings
			s.code = section
			s.save

			# @sections[s.code] = s
			# courseCode = "#{s.department}#{s.course}"
			# if @courses[courseCode] == nil
			# 	@courses[courseCode] = []
			# end
			# if @courses[courseCode][s.section.length-1] == nil
			# 	@courses[courseCode][s.section.length-1] = []
			# end
			# @courses[courseCode][s.section.length-1] << s
		end
	end
end

