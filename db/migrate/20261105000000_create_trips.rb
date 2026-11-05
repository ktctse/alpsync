class CreateTrips < ActiveRecord::Migration[8.1]
  def change
    create_table :trips do |t|
      t.string :name, null: false
      t.string :resort, null: false
      t.string :region, null: false
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.integer :party_size, null: false, default: 1
      t.string :skill_level, null: false
      t.string :languages, array: true, null: false, default: []
      t.string :looking_for, array: true, null: false, default: []
      t.string :offering, array: true, null: false, default: []
      t.string :contact_method, null: false
      t.string :contact_handle, null: false
      t.text :note
      t.string :edit_token, null: false
      t.boolean :demo, null: false, default: false

      t.timestamps
    end

    add_index :trips, :edit_token, unique: true
    add_index :trips, [ :region, :starts_on, :ends_on ]
    add_index :trips, :languages, using: :gin
  end
end
