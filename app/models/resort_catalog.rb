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

  # What riders actually call these places, including local-language names, so
  # both the resort search box and Claude's paste reader can find them.
  NICKNAMES = {
    "Niseko United" => %w[Niseko Hirafu Hanazono Annupuri ニセコ],
    "Rusutsu" => %w[ルスツ],
    "Kiroro" => %w[キロロ],
    "Furano" => %w[富良野],
    "Hakuba Happo-one" => %w[Happo Happoone 白馬八方尾根 八方],
    "Hakuba Goryu" => [ "Goryu", "Hakuba 47", "白馬五竜" ],
    "Nozawa Onsen" => %w[Nozawa 野沢温泉],
    "Shiga Kogen" => %w[Shiga 志賀高原],
    "Myoko Akakura" => %w[Myoko Akakura 妙高],
    "Naeba" => %w[苗場],
    "Gala Yuzawa" => %w[Gala Yuzawa ガーラ湯沢],
    "Whistler Blackcomb" => %w[Whistler Blackcomb WB],
    "Revelstoke" => %w[Revy],
    "Sun Peaks" => [],
    "Big White" => [],
    "Banff Sunshine" => [ "Sunshine", "Sunshine Village", "Banff" ],
    "Lake Louise" => %w[Louise]
  }.freeze

  # Searching a country or a short form finds every resort in the region.
  REGION_NICKNAMES = {
    "Hokkaido" => %w[Japan 北海道],
    "Nagano" => %w[Japan 長野],
    "Niigata" => %w[Japan 新潟],
    "British Columbia" => %w[BC Canada],
    "Alberta" => %w[AB Canada Rockies]
  }.freeze

  RESORT_TO_REGION = REGIONS.flat_map { |region, resorts| resorts.map { |resort| [ resort, region ] } }.to_h.freeze

  def self.regions = REGIONS.keys
  def self.resorts = RESORT_TO_REGION.keys
  def self.region_for(resort) = RESORT_TO_REGION[resort]
  def self.nicknames(resort) = NICKNAMES.fetch(resort, [])

  # Everything the resort search box needs, in list order.
  def self.for_search
    resorts.map do |resort|
      region = region_for(resort)
      { name: resort, region:, nicknames: nicknames(resort), places: [ region, *REGION_NICKNAMES.fetch(region, []) ] }
    end
  end
end
