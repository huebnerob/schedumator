# == Schema Information
#
# Table name: departments
#
#  id         :integer         not null, primary key
#  code       :string(255)
#  title      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Department < ActiveRecord::Base
end
