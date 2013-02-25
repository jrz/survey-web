class RenameColumnsTmpAndSecureToken < ActiveRecord::Migration
  def up
    rename_column :photos, :tmp, :image_tmp
    rename_column :photos, :secure_token, :image_secure_token
  end

  def down
    rename_column :photos, :image_tmp, :tmp
    rename_column :photos, :image_secure_token, :secure_token
  end
end
