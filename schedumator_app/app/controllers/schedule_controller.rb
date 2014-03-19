require 'Schedumator'
require 'Schedurailer'

class ScheduleController < ApplicationController
  def home
  	@name = params[:visitor_name]
  	# if @s == nil
  	# 	puts "REINIT SCHEDUMATOR"
  	# 	@s = Schedumator.new
  	# 	@s.loadSections
  	# end
   #  courseCodes = (@name != nil)? @name : 'ME354,ME358,ME342'
   #  schedules = @s.generateSchedules courseCodes.split(',')
   #  @courseMap = ""
   #  schedules.each do |schedule|
   #    @courseMap += "<br>" + "new schedule"
   #    @courseMap += schedule.readable
   #    @courseMap += "<br>" + "----------------"
   #  end
    courseCodes = (@name != nil) ? (@name.split ',') : ["ME354","ME358","ME342"]
    schedules = Schedurailer.generateSchedules(courseCodes);

    @courseMap = "" 
    schedules.each do |schedule|
      @courseMap += schedule.raw_json
      @courseMap += "<br><br>"
    end  	
  end

  def sign_in
  	@name = params[:visitor_name]
  end

  def schedule
    courses = params[:courses]
    courseCodes = (courses != nil) ? (courses.split ',') : ["ME354","ME358","ME342"]
    schedules = Schedurailer.generateSchedules(courseCodes);

    # respond_to do |format|
    #   format.html # index.html.erb
    # end
    if schedules.count == 0 
      @raw_json = "{\"status\":\"fail\",\"message\":\"no schedules found\"}".html_safe
    else 
      @raw_json = schedules[0].raw_json.html_safe
    end
    
  end 
end
