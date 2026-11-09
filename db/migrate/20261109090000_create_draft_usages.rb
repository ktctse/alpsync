class CreateDraftUsages < ActiveRecord::Migration[8.1]
  def change
    # One row per day: how many pasted messages Claude has read, site-wide.
    create_table :draft_usages do |t|
      t.date :day, null: false, index: { unique: true }
      t.integer :count, null: false, default: 0
    end
  end
end
