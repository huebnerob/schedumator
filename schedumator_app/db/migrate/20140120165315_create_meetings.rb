class CreateMeetings < ActiveRecord::Migration
  def change
    create_table :meetings do |t|
      
      t.integer :startTime
      t.integer :endTime

      # t.string :activity

      # t.string :room_id

      t.belongs_to :section

      t.timestamps
    end
  end
end
