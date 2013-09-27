require 'net/http'
require 'rexml/document'

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
	def initialize(code, blocks, callNumber)
		@code = code
		@blocks = blocks
		@callNumber = callNumber
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

	# block compare method -- returns:
	# :isequal if self collides with otherBlock (partially or completely)
	# :isbefore if self occurs before otherBlock
	# :isafter if self occurs after otherBlock
	def compare( otherBlock )
		s1 = self.startTime
		e1 = self.endTime
		s2 = otherBlock.startTime
		e2 = otherBlock.endTime
		starts12 = s1.compare(s2)
		end1Start2 = e1.compare(s2)
		start1end2 = s1.compare(e2)
		ends12 = e1.compare(e2)
		if starts12 == :isequal and ends12 == :isequal 
			(:isequal) # complete collide 
		elsif starts12 == :isbefore and ends12 == :isbefore and end1Start2 != :isafter
			(:isbefore) 
		elsif starts12 == :isafter and ends12 == :isafter and start1end2 != :isafter
			(:isafter)
		else
			(:isequal) #partial collisions cover the rest of the cases
		end
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

	def compare(otherSTime)
		if self.value < otherSTime.value
			(:isbefore)
		elsif self.value == otherSTime.value 
			(:isequal)
		else
			(:isafter)
		end 
	end
end

class Schedumator
	def initialize()
		@sections = []
		@courses = []

	end

	def getClasses
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
			puts section + " " + sectionTitle + " has " + sectionBlocks.length.to_s + " blocks."
			s = Section.new(section, sectionBlocks, sectionCallNumber)
			@sections << s

			c = Course.new(sectionTitle, section, [s] ) # set up a course for each section, for now, mush them later
			@courses << c

		end

	end
end

s = Schedumator.new
s.getClasses

puts "done"
