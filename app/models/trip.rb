# A rider's posted trip: where and when, who they are on the slopes, and what
# they're looking for or can offer. Riders don't have accounts; the private
# edit token is their key to edit or delete the post. A trip can cover several
# resorts in one date range.
class Trip < ApplicationRecord
  SKILL_LEVELS = %w[beginner intermediate advanced expert].freeze
  LANGUAGES = %w[English Cantonese Mandarin Japanese Korean French].freeze
  CONTACT_METHODS = { "whatsapp" => "WhatsApp", "line" => "LINE", "wechat" => "WeChat",
                      "instagram" => "Instagram", "email" => "Email" }.freeze
  MAX_RESORTS = 4

  has_secure_token :edit_token

  before_validation :clean_lists, :set_regions

  validates :name, presence: true, length: { maximum: 40 }
  validates :starts_on, :ends_on, presence: true
  validates :party_size, numericality: { only_integer: true, in: 1..8 }
  validates :skill_level, inclusion: { in: SKILL_LEVELS }
  # Contact details are optional: riders can talk in Alpsync messages instead.
  validates :contact_method, inclusion: { in: CONTACT_METHODS.keys }, if: -> { contact_handle.present? }
  validates :contact_handle, length: { maximum: 80 }
  validates :note, length: { maximum: 500 }
  validate :resorts_known, :dates_in_order, :languages_known, :tags_known

  scope :upcoming, -> { where(ends_on: Date.current..) }
  scope :demo, -> { where(demo: true) }
  scope :newest_first, -> { order(created_at: :desc) }

  # Shorthand for a single-resort trip (sample data, "post a trip here" links).
  def resort=(name)
    self.resorts = [ name ].compact_blank
  end

  def contact_label = CONTACT_METHODS[contact_method]

  def matches(limit: 10) = Matcher.new(self).matches(limit:)

  private

  def clean_lists
    self.resorts = Array(resorts).compact_blank.uniq
    self.languages = Array(languages).compact_blank.uniq
    self.looking_for = Array(looking_for).compact_blank.uniq
    # Symmetric tags describe a shared plan, so they only live in "looking for".
    self.offering = Array(offering).compact_blank.uniq - TagCatalog.symmetric_keys
  end

  def set_regions
    self.regions = resorts.filter_map { |resort| ResortCatalog.region_for(resort) }.uniq
  end

  def resorts_known
    errors.add(:resorts, "needs at least one") if resorts.empty?
    errors.add(:resorts, "can have up to #{MAX_RESORTS}") if resorts.size > MAX_RESORTS
    errors.add(:resorts, "includes one that isn't on our list yet") if (resorts - ResortCatalog.resorts).any?
  end

  def dates_in_order
    return if starts_on.blank? || ends_on.blank?

    errors.add(:ends_on, "must be on or after the start date") if ends_on < starts_on
    errors.add(:ends_on, "can't be in the past") if ends_on < Date.current
  end

  def languages_known
    errors.add(:languages, "needs at least one") if languages.empty?
    errors.add(:languages, "includes one we don't support") if (languages - LANGUAGES).any?
  end

  def tags_known
    errors.add(:looking_for, "needs at least one tag") if looking_for.empty?
    unknown = (looking_for + offering) - TagCatalog.keys
    errors.add(:base, "Unknown tags: #{unknown.join(', ')}") if unknown.any?
  end
end
