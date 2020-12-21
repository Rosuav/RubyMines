class CreateGames < ActiveRecord::Migration[6.1]
  def change
    create_table :games do |t|
      t.integer :width
      t.integer :height
      t.integer :mines
    end
  end
end
