# Finds and ranks other trips that suit a given trip.
#
# Step 1 (hard filters, in SQL): still upcoming, at least one region in common,
# overlapping dates, and a shared language. A match you can't talk to isn't a match.
#
# Step 2 (scoring, in Ruby): points for each need the other rider covers, in
# both directions, a bonus when it works both ways, and small tie-breakers.
# Every point comes with a plain-English reason shown on the match card.
class Matcher
  Match = Data.define(:trip, :score, :reasons, :mutual)

  POINTS = {
    they_cover_my_need: 3,
    i_cover_their_need: 3,
    mutual_bonus: 2,
    shared_plan: 2,
    same_resort: 1,
    similar_level: 1
  }.freeze

  def initialize(trip)
    @trip = trip
  end

  def matches(limit: 10)
    candidates.filter_map { |other| evaluate(other) }
              .sort_by { |match| [ -match.score, match.trip.starts_on ] }
              .first(limit)
  end

  private

  attr_reader :trip

  def candidates
    Trip.upcoming
        .where.not(id: [ trip.id, *trip.unmatched_trip_ids ])
        .where("regions && ARRAY[?]::varchar[]", trip.regions)
        .where("starts_on <= ? AND ends_on >= ?", trip.ends_on, trip.starts_on)
        .where("languages && ARRAY[?]::varchar[]", trip.languages)
  end

  def evaluate(other)
    they_cover = other.offering & trip.looking_for
    i_cover = trip.offering & other.looking_for
    shared = trip.looking_for & other.looking_for & TagCatalog.symmetric_keys

    # Only tag overlap creates a match; resort and level just break ties.
    return if they_cover.empty? && i_cover.empty? && shared.empty?

    # Mutual means each rider covers a need of the other's. A shared plan counts
    # as the second half, but on its own (we both want a lodge mate) it's
    # common enough that badging it would make every match look mutual.
    mutual = (they_cover.any? && i_cover.any?) || (shared.any? && (they_cover.any? || i_cover.any?))
    score = 0
    reasons = []

    if they_cover.any?
      score += POINTS[:they_cover_my_need] * they_cover.size
      reasons << "They can offer what you need: #{TagCatalog.labels(they_cover).to_sentence}"
    end
    if i_cover.any?
      score += POINTS[:i_cover_their_need] * i_cover.size
      reasons << "You can offer what they need: #{TagCatalog.labels(i_cover).to_sentence}"
    end
    if shared.any?
      score += POINTS[:shared_plan] * shared.size
      reasons << "You both want a #{TagCatalog.labels(shared).to_sentence.downcase}"
    end
    score += POINTS[:mutual_bonus] if mutual
    same_resorts = trip.resorts & other.resorts
    if same_resorts.any?
      score += POINTS[:same_resort]
      reasons << "#{'Same resort'.pluralize(same_resorts.size)}: #{same_resorts.to_sentence}"
    end
    if shared.include?("ride_buddy") && similar_level?(other)
      score += POINTS[:similar_level]
      reasons << "Similar riding level"
    end

    Match.new(trip: other, score:, reasons:, mutual:)
  end

  def similar_level?(other)
    (Trip::SKILL_LEVELS.index(trip.skill_level) - Trip::SKILL_LEVELS.index(other.skill_level)).abs <= 1
  end
end
