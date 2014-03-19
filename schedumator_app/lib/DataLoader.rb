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
		return ['2014S', '2013F']
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
		xml_data = File.read("2014s.xml")
		@doc = REXML::Document.new(xml_data)
	end

	# uses regex to find the course code and section shortcode from a full section code
	#   E 344A  --> department E course 344 section A
	#   E 421X2 --> department E course 421 section X2
	def self.divideCode longCode
		# regex to find n characters, a space, then n numbers
		# the rest is the section code
		# "hello".rpartition(/.l/)        #=> ["he", "ll", "o"]

		# this regex searches for three numbers sandwiched between letters
		regex = /(?<=[A-Z]) ?[0-9]{3}(?=[A-Z])/
		# strip whitespace and search
		results = longCode.gsub(/\s+/, "").rpartition(regex);

		# puts "#{results[0]}|#{results[1]}|#{results[2]}"

		if results[0].length > 0 and results[1].length > 0 and results[2].length > 0
			# valid results
			departmentCode = results[0]
			courseCode = results[1]
			sectionShortcode = results[2]
			return [departmentCode, courseCode, sectionShortcode]
		else 
			# invalid results
			return []
		end
	end

	def self.generateSections
		courses = {}
		@doc.elements.each 'Semester/Course' do |crs|
			section = crs.attributes["Section"]
			codes = DataLoader.divideCode(section)

			courseCode = codes[0]+codes[1]
			sectionCode = codes[2]

			course = courses[courseCode]
			if (course == nil) 
				course = Course.new
				course.code = courseCode
				courses[courseCode] = course
			end

			sectionTitle = crs.attributes["Title"]
			sectionCallNumber = crs.attributes["CallNumber"]
			sectionMeetings = []
			crs.elements.each('Meeting') do |mtg|
				mtgDays = mtg.attributes["Day"]
				mtgStart = mtg.attributes["StartTime"] 
				mtgEnd = mtg.attributes["EndTime"]
				if mtgStart != nil
					sectionMeetings << [mtgDays, mtgStart, mtgEnd]
				end
			end

			s = Section.generate sectionMeetings
			s.code = sectionCode
			s.save

			course.sections << s
			course.save
		end
	end
end

