# A trip can now cover several resorts in one date range (Hakuba and Nozawa,
# Jan 10-16), so the single resort and region become lists. Existing trips
# keep their one resort.
class SupportMultipleResorts < ActiveRecord::Migration[8.1]
  def up
    add_column :trips, :resorts, :string, array: true, null: false, default: []
    add_column :trips, :regions, :string, array: true, null: false, default: []
    execute "UPDATE trips SET resorts = ARRAY[resort], regions = ARRAY[region]"

    remove_index :trips, [ :region, :starts_on, :ends_on ]
    remove_column :trips, :resort
    remove_column :trips, :region
    add_index :trips, :regions, using: :gin
    add_index :trips, [ :starts_on, :ends_on ]
  end

  def down
    add_column :trips, :resort, :string
    add_column :trips, :region, :string
    execute "UPDATE trips SET resort = resorts[1], region = regions[1]"
    change_column_null :trips, :resort, false
    change_column_null :trips, :region, false

    remove_index :trips, [ :starts_on, :ends_on ]
    remove_index :trips, :regions
    remove_column :trips, :resorts
    remove_column :trips, :regions
    add_index :trips, [ :region, :starts_on, :ends_on ]
  end
end
