# == Schema Information
#
# Table name: sections
#
#  id             :integer         not null, primary key
#  code           :string(255)
#  courseCode     :string(255)
#  callNumber     :string(255)
#  credits        :integer
#  instructorCode :string(255)
#  status         :string(255)
#  currentEnroll  :integer
#  maxEnroll      :integer
#  course_id      :integer
#  created_at     :datetime
#  updated_at     :datetime
#

class Section < ActiveRecord::Base
	belongs_to :course
	has_many :meetings

	def self.generate meetingsData
		newSection = Section.create
		meetingsData.each do |mtgData|
			# mtgData[0] = day, [1] = startString, [2] = endString
			mtgData[0].split("").each do |day|
				newSection.meetings << Meeting.generate(day, mtgData[1], mtgData[2])
			end
		end
		newSection.save
		return newSection
	end

	def checkWithSct(otherSct)
		self.meetings.each do |m|
			if otherSct.checkWithBlock(m) == :conflicts
				return :conflicts
			end
		end
		:clear
	end

	def checkWithBlock(meeting)
		self.meetings.each do |m|
			if m.compare(meeting) == :iscoincident
				# puts "conflict detected"
				return :conflicts
			end
		end
		return :clear
	end

	def readable
		string = self.course.code + self.code + "\n"
		self.meetings.each do |m|
			string = string + m.readable
			string = string + "\n"
		end
		return string
	end

	def fullcode 
		return self.course.code + "" + self.code
	end

end