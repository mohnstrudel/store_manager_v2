class CreateFranchises < ActiveRecord::Migration[7.0]
  def change
    create_table :franchises do |t|
      t.string :title

      t.timestamps
    end
  end
end
