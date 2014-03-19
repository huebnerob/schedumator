class CreateCourses < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      # t.belongs_to :department
      # t.belongs_to :semester

      t.string :departmentString  # temporary, until we get dept objects

      t.string :code
      t.string :title


      t.timestamps
    end
  end
end
