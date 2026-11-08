# Chat between two riders' trips. A conversation belongs to exactly two trips
# (stored in id order so each pair has one conversation), and both it and its
# messages are deleted with either trip.
class CreateConversationsAndMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :trip_a, null: false, foreign_key: { to_table: :trips, on_delete: :cascade }
      t.references :trip_b, null: false, foreign_key: { to_table: :trips, on_delete: :cascade }
      t.datetime :trip_a_read_at
      t.datetime :trip_b_read_at
      t.datetime :reported_at

      t.timestamps
    end
    add_index :conversations, [ :trip_a_id, :trip_b_id ], unique: true

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }
      t.references :sender, null: false, foreign_key: { to_table: :trips, on_delete: :cascade }
      t.text :body, null: false

      t.timestamps
    end
  end
end
