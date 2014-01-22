# == Schema Information
#
# Table name: semesters
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  start      :date
#  end        :date
#  created_at :datetime
#  updated_at :datetime
#

class Semester < ActiveRecord::Base
end
