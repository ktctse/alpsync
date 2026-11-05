# A rider's posted trip: where and when, who they are on the slopes, and what
# they're looking for or can offer. Riders don't have accounts; the private
# edit token is their key to edit or delete the post.
class Trip < ApplicationRecord
  SKILL_LEVELS = %w[beginner intermediate advanced expert].freeze
  LANGUAGES = %w[English Cantonese Mandarin Japanese Korean French].freeze
  CONTACT_METHODS = { "whatsapp" => "WhatsApp", "line" => "LINE", "wechat" => "WeChat",
                      "instagram" => "Instagram", "email" => "Email" }.freeze

  has_secure_token :edit_token

  before_validation :set_region, :clean_lists

  validates :name, presence: true, length: { maximum: 40 }
  validates :resort, inclusion: { in: ResortCatalog.resorts, message: "isn't on our list yet" }
  validates :starts_on, :ends_on, presence: true
  validates :party_size, numericality: { only_integer: true, in: 1..8 }
  validates :skill_level, inclusion: { in: SKILL_LEVELS }
  validates :contact_method, inclusion: { in: CONTACT_METHODS.keys }
  validates :contact_handle, presence: true, length: { maximum: 80 }
  validates :note, length: { maximum: 500 }
  validate :dates_in_order, :languages_known, :tags_known

  scope :upcoming, -> { where(ends_on: Date.current..) }
  scope :demo, -> { where(demo: true) }
  scope :newest_first, -> { order(created_at: :desc) }

  def contact_label = CONTACT_METHODS.fetch(contact_method)

  def matches(limit: 10) = Matcher.new(self).matches(limit:)

  private

  def set_region
    self.region = ResortCatalog.region_for(resort)
  end

  def clean_lists
    self.languages = Array(languages).compact_blank.uniq
    self.looking_for = Array(looking_for).compact_blank.uniq
    # Symmetric tags describe a shared plan, so they only live in "looking for".
    self.offering = Array(offering).compact_blank.uniq - TagCatalog.symmetric_keys
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
