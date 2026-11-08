# Riders can now talk in Alpsync messages, so sharing a phone number or handle
# when posting a trip is optional.
class MakeTripContactOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :trips, :contact_method, true
    change_column_null :trips, :contact_handle, true
  end
end
