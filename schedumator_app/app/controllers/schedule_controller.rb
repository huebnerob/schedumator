require 'Schedumator'

class ScheduleController < ApplicationController
  def home
  	@name = params[:visitor_name]
  	if @s == nil
  		puts "REINIT SCHEDUMATOR"
  		@s = Schedumator.new
  		@s.loadSections
  	end
    courseCodes = (@name != nil)? @name : 'ME354,ME358,ME342'
    schedules = @s.generateSchedules courseCodes.split(',')
    @courseMap = ""
    schedules.each do |schedule|
      @courseMap += "<br>" + "new schedule"
      @courseMap += schedule.readable
      @courseMap += "<br>" + "----------------"
    end
  	
  end

  def sign_in
  	@name = params[:visitor_name]
  end
end
