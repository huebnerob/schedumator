class SchedumatorController < ApplicationController

	def initApp
		@status = "Not loaded."
		if DataLoader.start
			@status = "Data loaded successfully."
		else
			@status = "Error"
		end

		# test queries 
		@sectionCount = Section.all.size
		@courseCount = Course.all.size
		@meetingCount = Meeting.all.size
		# prepare interfaces
	end

	def kill 
		Course.destroy_all
		Section.destroy_all
		Meeting.destroy_all
		@status = "SUCCESS"
		@sectionCount = Section.all.size
		@courseCount = Course.all.size
		@meetingCount = Meeting.all.size
	end

	def search 

	end

end
