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

K_SECONDSINDAY = 86400
K_SECONDSINHOUR = 3600
K_SECONDSINMINUTE = 60

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
		return (self.endTime - self.startTime)
	end

	# block compare method -- returns:
	# :iscoincident if self collides with otherBlock (partially or completely)
	# :isbefore if self occurs before otherBlock
	# :isafter if self occurs after otherBlock
	def compare( otherBlock )
		s1 = self.startTime
		e1 = self.endTime
		s2 = otherBlock.startTime
		e2 = otherBlock.endTime
		if s1 < s2
			len1 = self.length
			delta = (s2-s1)
			if len1 > delta
				return :iscoincident
			end
			return :isbefore
		elsif s2 < s1
			len2 = otherBlock.length
			delta = (s1-s2)
			if len2 > delta
				return :iscoincident
			end
			return :isafter
		else # s1 == s2
			# they have to collide
			return :iscoincident
		end
	end

	def readable 
		(" " + self.startTime.to_s + " to " + self.endTime.to_s)
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

	def day
		return (self.startTime / K_SECONDSINDAY).floor
	end

	def start_hour 
		hour = ((self.startTime % K_SECONDSINDAY) / K_SECONDSINHOUR)
		minute = ((self.startTime % K_SECONDSINHOUR) / K_SECONDSINMINUTE)
		return hour.to_s.rjust(2, '0') + ":" + minute.to_s.rjust(2, '0')
	end

	def end_hour
		hour = ((self.endTime % K_SECONDSINDAY) / K_SECONDSINHOUR)
		minute = ((self.endTime % K_SECONDSINHOUR) / K_SECONDSINMINUTE)
		return hour.to_s.rjust(2, '0') + ":" + minute.to_s.rjust(2, '0')
	end
end
