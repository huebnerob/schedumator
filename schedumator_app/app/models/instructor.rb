# == Schema Information
#
# Table name: instructors
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Instructor < ActiveRecord::Base
end
