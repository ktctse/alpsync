# The fixed tag vocabulary riders pick from.
#
# Complementary tags match one rider's "looking for" against another rider's
# "can offer" (I need a Driver, you can offer Driver). Instructors and students
# use the same rule: an instructor offers Instructor and looks for Student.
#
# Symmetric tags describe something both riders want together (sharing a lodge,
# riding together), so they only ever go in "looking for" and match when both
# riders picked the same one.
module TagCatalog
  Tag = Data.define(:key, :label, :kind, :hint) do
    def symmetric? = kind == :symmetric
  end

  ALL = [
    Tag.new(key: "instructor", label: "Instructor", kind: :complementary, hint: "Certified or experienced coach"),
    Tag.new(key: "student", label: "Student", kind: :complementary, hint: "Wants lessons"),
    Tag.new(key: "driver", label: "Driver", kind: :complementary, hint: "Has a car for the trip"),
    Tag.new(key: "idp", label: "International Driving Permit", kind: :complementary, hint: "Can legally drive in Japan"),
    Tag.new(key: "gear", label: "Gear to lend", kind: :complementary, hint: "Spare board, skis or outerwear"),
    Tag.new(key: "japanese", label: "Japanese speaker", kind: :complementary, hint: "Can help with bookings and signs"),
    Tag.new(key: "room", label: "Spare room", kind: :complementary, hint: "A room or bed in a place that's already booked"),
    Tag.new(key: "lodge_mate", label: "Lodge mate", kind: :symmetric, hint: "Book a place together and split it"),
    Tag.new(key: "ride_buddy", label: "Ride buddy", kind: :symmetric, hint: "Someone to ride with")
  ].freeze

  BY_KEY = ALL.index_by(&:key).freeze

  def self.keys = BY_KEY.keys
  def self.complementary = ALL.reject(&:symmetric?)
  def self.symmetric = ALL.select(&:symmetric?)
  def self.symmetric_keys = symmetric.map(&:key)
  def self.label(key) = BY_KEY.fetch(key).label
  def self.labels(keys) = keys.map { |key| label(key) }
end
