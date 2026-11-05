class AddAvatarToTrips < ActiveRecord::Migration[8.1]
  def change
    # Filename of a photo in app/assets/images/avatars. Only sample trips set
    # it for now; riders without one get an initial avatar.
    add_column :trips, :avatar, :string
  end
end
