class CreateUnmatches < ActiveRecord::Migration[8.1]
  def change
    # A rider unmatching another. It applies both ways, and goes when either trip does.
    create_table :unmatches do |t|
      t.references :trip, null: false, foreign_key: { on_delete: :cascade }
      t.references :other_trip, null: false, foreign_key: { to_table: :trips, on_delete: :cascade }
      t.timestamps
    end
    add_index :unmatches, %i[trip_id other_trip_id], unique: true
  end
end
