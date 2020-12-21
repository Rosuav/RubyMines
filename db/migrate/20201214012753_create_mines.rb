class CreateMines < ActiveRecord::Migration[6.1]
  def change
    create_table :mines do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :x
      t.integer :y
    end
  end
end
