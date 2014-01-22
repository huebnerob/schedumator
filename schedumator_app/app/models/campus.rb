# == Schema Information
#
# Table name: campus
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Campus < ActiveRecord::Base
end
