# == Schema Information
#
# Table name: meetings
#
#  id         :integer         not null, primary key
#  startTime  :integer
#  endTime    :integer
#  activity   :string(255)
#  room_id    :string(255)
#  section_id :integer
#  created_at :datetime
#  updated_at :datetime
#

# Meeting - a single event with a start and end time, recurring on a weekly basis
class Meeting < ActiveRecord::Base
	belongs_to :section

	# attr_accessor :startTime, :endTime

	def self.generate day, startTimeString, endTimeString
		newMeeting = Meeting.create
		newMeeting.startTime = Meeting.toWeekSeconds(day, startTimeString)
		newMeeting.endTime = Meeting.toWeekSeconds(day, endTimeString)
		newMeeting.save
		return newMeeting
	end

	# converts a time and day string to a 'weekseconds' value (seconds from beginning of week)
	# 'W' "10:00:00Z" --> 208800
	def self.toWeekSeconds day, timeString
		dayIndex = ['M','T','W','R','F','S','U'].index day
		components = timeString.chop.split(':')
		hour = components[0].to_i + 4 #correct for UTC time
		minute = components[1].to_i
		return ((dayIndex*24+hour)*60+minute)*60
	end

	def length
		return (@endTime - @startTime)
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
		if s1 < s2
			len1 = self.length
			delta = (s2.value-s1.value)
			if len1 > delta
				return :iscoincident
			end
			return :isbefore
		elsif s2 < s1
			len2 = otherBlock.length
			delta = (s1.value-s2.value)
			if len2 > delta
				return :iscoincident
			end
			return :isafter
		else # s1 == s2
			# they have to collide
			return :iscoincident
		end
	end

	# def readableFull
	# 	days = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
	# 	printHour = @hour
	# 	printStatus = "AM"
	# 	if printHour > 12
	# 		printHour = printHour-12
	# 		printStatus = "PM"
	# 	end
	# 	(days[@day] + " " + printHour.to_s + ":" + @minute.to_s + printStatus)
	# end
end
