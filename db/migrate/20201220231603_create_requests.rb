class CreateRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :requests do |t|
      # TODO: Make (width,height,mines) the primary key
      t.integer :width
      t.integer :height
      t.integer :mines
    end
  end
end
