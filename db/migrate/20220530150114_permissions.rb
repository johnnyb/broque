class Permissions < ActiveRecord::Migration[7.0]
  def change
    create_table :permissions do |t|
      t.string :permission_on_type
      t.references :permission_on
      t.string :uid
      t.string :permission
    end
    add_index :permissions, :uid

    add_column :channels, :authentication_required, :boolean, :default => false 
    add_column :channels, :permission_required, :boolean, :default => false 
  end
end
