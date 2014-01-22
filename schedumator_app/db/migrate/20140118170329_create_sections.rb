class CreateSections < ActiveRecord::Migration
  def change
    create_table :sections do |t|
      t.string :code
      t.string :courseCode
      t.string :callNumber
      t.integer :credits
      t.string :instructorCode
      t.string :status
      t.integer :currentEnroll
      t.integer :maxEnroll

      t.belongs_to :course

      t.timestamps
    end
  end
end
