# == Schema Information
#
# Table name: buildings
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Building < ActiveRecord::Base
end
