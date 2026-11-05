# Resorts riders can pick, grouped by region. Matching only pairs riders in the
# same region, so the region is derived from the resort rather than typed in.
module ResortCatalog
  REGIONS = {
    "Hokkaido" => [ "Niseko United", "Rusutsu", "Kiroro", "Furano" ],
    "Nagano" => [ "Hakuba Happo-one", "Hakuba Goryu", "Nozawa Onsen", "Shiga Kogen" ],
    "Niigata" => [ "Myoko Akakura", "Naeba", "Gala Yuzawa" ],
    "British Columbia" => [ "Whistler Blackcomb", "Revelstoke", "Sun Peaks", "Big White" ],
    "Alberta" => [ "Banff Sunshine", "Lake Louise" ]
  }.freeze

  RESORT_TO_REGION = REGIONS.flat_map { |region, resorts| resorts.map { |resort| [ resort, region ] } }.to_h.freeze

  def self.regions = REGIONS.keys
  def self.resorts = RESORT_TO_REGION.keys
  def self.region_for(resort) = RESORT_TO_REGION[resort]
end
