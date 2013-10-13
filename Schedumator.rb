require 'net/http'
require 'rexml/document'
require 'pp'

# Course - contains one or more sections from which to choose 
#   this is not separated out from sections in the data source and will have to be parsed manually
#   ...if we want it
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
class Section
	def initialize(code, blocks, callNumber, title)
		@code = code
		@blocks = blocks
		@callNumber = callNumber
		@title = title
	end

	attr_accessor :title

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
		string = @code + "\n"
		@blocks.each do |b|
			string = string + b.readable
			string = string + "\n"
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
				puts "sched invalid"
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
		string = "Valid\n"
		@sections.each do |s|
			string = string + s.readable
			string = string + "\n"
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
			@sections[section] = s

			# c = Course.new(sectionTitle, section, [s] ) # set up a course for each section, for now, mush them later
			# @courses[section] = c
		end
	end

	def mashCourses
		@sections.each do |code,sct|
			if @courses[sct.title] == nil
				@courses[sct.title] = []
			end
			@courses[sct.title] << code
		end
	end

	def courseMap 
		map = ""
		@courses.each do |title,codes|
			map += "#{title}\n"
			codes.each do |code| 
				map += "   #{code}\n"
			end
			map += "\n"
		end
		return map
	end

	# makes a schedule with an array of codes like ['ME 354A','PE 200E8']
	def makeSchedule( codes )
		sections = []
		codes.each do |code|
			sections << @sections[code]
		end
		(Schedule.new(sections))
	end
end

s = Schedumator.new
s.loadSections
s.mashCourses
puts s.courseMap
schedule = s.makeSchedule ["ME 354A","ME 354A"]

puts "Schedule Complete."
puts schedule.readable

puts "done"
