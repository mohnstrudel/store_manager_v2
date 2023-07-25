class CreateShapes < ActiveRecord::Migration[7.0]
  def change
    create_table :shapes do |t|
      t.string :title

      t.timestamps
    end
  end
end
