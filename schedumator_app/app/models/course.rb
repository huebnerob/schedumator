# == Schema Information
#
# Table name: courses
#
#  id            :integer         not null, primary key
#  department_id :integer
#  semester_id   :integer
#  code          :string(255)
#  title         :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#

class Course < ActiveRecord::Base
	# belongs_to :department
	# belongs_to :semester

	has_many :sections

	def binSections 
		sectionsBinned = [];
		sections.each do |section|
			if sectionsBinned[section.code.length-1] == nil
				sectionsBinned[section.code.length-1] = []
			end
			sectionsBinned[section.code.length-1] << section
		end
		return sectionsBinned
	end
end
