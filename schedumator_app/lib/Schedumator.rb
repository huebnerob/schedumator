require 'net/http'
require 'rexml/document'
require 'pp'

# Course - contains one or more sections from which to choose 
#   this is not separated out from sections in the XML and will have to be parsed manually
#   ...if we want it (we do)
# => code is the course id, eg. ME 345
class Course
	def initialize(code, name, sections)
		@name = name
		@code = code
		@sections = sections
	end
end

# Section - contains one or more blocks representing meeting times for the class section
# 	code is the section id, e.g. ME 345A
#   blocks are the meeting times for the section
class Section
	def initialize(code, blocks, callNumber, title)
		dcs = divideCode(code)
		@department = dcs[0]
		@course = dcs[1]
		@section = dcs[2]
		@code = "#{@department}.#{@course}.#{@section}"
		@blocks = blocks
		@callNumber = callNumber
		@title = title
	end

	attr_accessor :title
	attr_accessor :code
	attr_accessor :department
	attr_accessor :course
	attr_accessor :section

	# uses regex to find the course code and section shortcode from a full section code
	#   E 344A  --> department E course 344 section A
	#   E 421X2 --> department E course 421 section X2
	def divideCode longCode
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


	def checkWithSct(otherSct)
		@blocks.each do |b|
			if otherSct.checkWithBlock(b) == :conflicts
				return :conflicts
			end
		end
		:clear
	end

	def checkWithBlock(block)
		@blocks.each do |b|
			if b.compare(block) == :iscoincident
				puts "conflict detected"
				return :conflicts
			end
		end
		return :clear
	end

	def readable
		string = @code + "<br>"
		@blocks.each do |b|
			string = string + b.readable
			string = string + "<br>"
		end
		string
	end

end

# Used to handle both singular day strings "M" and multiple day strings "MWF"
# returns an array of blocks, length >= 1
def makeBlocks(days, startTimeString, endTimeString, info)
	blocks = []
	days.split("").each do |d|
		b = Block.new(d, startTimeString, endTimeString, info)
		blocks << b
	end
	(blocks)
end


# Block - Represents a range of time that is 'blocked' during a certain weekday from start HH:MM to end HH:MM 
#  - add info string to store location of meeting or other relevant info
class Block
	def initialize(day, startTimeString, endTimeString, info = "")
		@startTime = STime.new day, startTimeString
		@endTime = STime.new day, endTimeString
		@info = info
	end

	attr_accessor :startTime
	attr_accessor :endTime

	def length
		return (@endTime.value - @startTime.value)
	end

	# block compare method -- returns:
	# :iscoincident if self collides with otherBlock (partially or completely)
	# :isbefore if self occurs before otherBlock
	# :isafter if self occurs after otherBlock
	def compare( otherBlock )
		s1 = @startTime
		e1 = @endTime
		s2 = otherBlock.startTime
		e2 = otherBlock.endTime
		starts12 = s1.compare(s2)
		if starts12 == :isbefore
			len1 = self.length
			delta = (s2.value-s1.value)
			if len1 > delta
				return :iscoincident
			end
			return :isbefore
		elsif starts12 == :isafter
			len2 = otherBlock.length
			delta = (s1.value-s2.value)
			if len2 > delta
				return :iscoincident
			end
			return :isafter
		elsif starts12 == :iscoincident
			# they have to collide
			return :iscoincident
		else
			# invalid compare value

		end
	end

	def readable 
		(@startTime.readableDay + " " + @startTime.readableTime + " to " + @endTime.readableTime)
	end
end

# STime - represents a weekday (0-sunday) and HH:MM value
class STime
	def initialize(day, timeString)
		@day = ['M','T','W','R','F','S','U'].index day
		components = timeString.chop.split(':')
		@hour = components[0].to_i + 4 #correct for UTC time
		@minute = components[1].to_i
	end
	
	def value
		((@day*24+@hour)*60+@minute)*60 #returns seconds from start of week
	end

	def readableFull
		days = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
		printHour = @hour
		printStatus = "AM"
		if printHour > 12
			printHour = printHour-12
			printStatus = "PM"
		end
		(days[@day] + " " + printHour.to_s + ":" + @minute.to_s + printStatus)
	end

	def readableTime
		printHour = @hour
		printStatus = "AM"
		if printHour > 12
			printHour = printHour-12
			printStatus = "PM"
		end
		(printHour.to_s + ":" + @minute.to_s + printStatus)
	end

	def readableDay
		["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"][@day]
	end

	def compare(otherSTime)
		if self.value < otherSTime.value
			(:isbefore)
		elsif self.value == otherSTime.value 
			(:iscoincident)
		else
			(:isafter)
		end 
	end
end

class Schedule
	def initialize( sections )
		@status = :valid
		@sections = []
		sections.each do |nSct| 
			if addSection(nSct) == :conflicts
				@status = :invalid
			end
		end
	end

	attr_accessor :status

	def addSection( newSection )
		# check all sections for conflicts
		@sections.each do |sct|
			if sct.checkWithSct(newSection) == :conflicts
				@sections << newSection
				return :conflicts
			end
		end
		@sections << newSection
		:clear
	end

	def readable
		return "invalid schedule." if @status == :invalid
		string = "Valid<br>"
		@sections.each do |s|
			string = string + s.readable
			string = string + "<br>"
		end
		string
	end
end


class Schedumator
	def initialize()
		@sections = {}
		@courses = {}

	end

	attr_accessor :courses

	def loadSections
		# url = 'http://www.stevens.edu/scheduler/core/core.php?cmd=getxml&term=2013F'
		# xml_data = Net::HTTP.get_response(URI.parse(url)).body

		xml_data = File.read("2013f.xml")
		doc = REXML::Document.new(xml_data)
		doc.elements.each 'Semester/Course' do |crs|
			section = crs.attributes["Section"]
			sectionTitle = crs.attributes["Title"]
			sectionCallNumber = crs.attributes["CallNumber"]
			sectionBlocks = []
			crs.elements.each('Meeting') do |mtg|
				mtgDays = mtg.attributes["Day"]
				mtgStart = mtg.attributes["StartTime"] 
				mtgEnd = mtg.attributes["EndTime"]
				mtgBuilding = mtg.attributes["Building"]
				mtgRoom = mtg.attributes["Room"]
				mtgInfo = mtgBuilding + mtgRoom 
				if mtgStart != nil
					sectionBlocks.concat makeBlocks(mtgDays,mtgStart,mtgEnd,mtgInfo)
				end
			end

			# puts section + " " + sectionTitle + " has " + sectionBlocks.length.to_s + " blocks."
			s = Section.new(section, sectionBlocks, sectionCallNumber, sectionTitle)
			# @sections[s.code] = s
			courseCode = "#{s.department}#{s.course}"
			if @courses[courseCode] == nil
				@courses[courseCode] = []
			end
			if @courses[courseCode][s.section.length-1] == nil
				@courses[courseCode][s.section.length-1] = []
			end
			@courses[courseCode][s.section.length-1] << s
		end
	end
	
	def courseMap 
		map = ""
		@courses.each do |code,sectionBundles|
			map += "<h3>#{code}</h3>"
			sectionBundles.each do |sections| 
				map += "<br>"
				if sections != nil
					sections.each do |section|
						map += "   <li>#{section.code}</li>"
					end
				end
			end
			map += "<br>"
		end
		return map
	end

	# makes a schedule with an array of sections
	def makeScheduleWithSections(sections)
		newSchedule = Schedule.new(sections)
		# check if valid?
		return newSchedule
	end

	def generateSchedules(courseCodes)
		# get sections for each course code
		# permutate all possible section possiblities 
		allSectionCombos = [[]]
		tempCombos = []
		courseCodes.each do |courseCode|
			courseSectionBundles = @courses[courseCode]
			courseSectionBundles.each do |courseSections|
				courseSections.each do |section|
					allSectionCombos.each do |combo|
						newCombo = Array.new(combo)
						newCombo << section
						tempCombos << newCombo
					end
				end
				allSectionCombos = tempCombos
				tempCombos = []
			end
		end
		schedules = []
		allSectionCombos.each do |combo|
			newSchedule = Schedule.new(combo)
			if newSchedule.status == :valid
				schedules << newSchedule
			else 
				# schedules << newSchedule # show all schedules
			end
		end
		return schedules
	end
end

# s = Schedumator.new
# s.loadSections
# puts s.courseMap

# schedule = s.generateSchedules ['ME354','ME358','ME342']

# puts "Schedule Complete."

# schedule.each do |sections|
# 	puts "new schedule"
# 	sections.each do |section|
# 		puts section.readable
# 	end
# 	puts "----------------"
# end

# puts "done"
