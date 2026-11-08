module ApplicationHelper
  FIELD_CLASS = "w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-800 " \
                "focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-200".freeze

  def field_class = FIELD_CLASS

  SHORT_REGIONS = { "British Columbia" => "BC", "Alberta" => "AB" }.freeze

  # "BC" rather than "British Columbia", so resort lines fit on a card.
  def short_region(region) = SHORT_REGIONS.fetch(region, region)

  # "Hakuba Happo-one + Nozawa Onsen"
  def resort_list(trip) = trip.resorts.join(" + ")

  # "Hakuba Happo-one + Nozawa Onsen, Nagano"
  def resorts_with_regions(trip) = "#{resort_list(trip)}, #{trip.regions.map { |region| short_region(region) }.join(' / ')}"

  # "Jan 10–14", or "Jan 30–Feb 3" when the trip crosses a month.
  def trip_dates(trip)
    starts, ends = trip.starts_on, trip.ends_on
    return starts.strftime("%b %-d") if starts == ends

    finish = starts.month == ends.month ? ends.strftime("%-d") : ends.strftime("%b %-d")
    "#{starts.strftime('%b %-d')}–#{finish}"
  end

  AVATAR_COLORS = [
    "bg-sky-100 text-sky-800", "bg-emerald-100 text-emerald-800", "bg-violet-100 text-violet-800",
    "bg-amber-100 text-amber-800", "bg-rose-100 text-rose-800", "bg-teal-100 text-teal-800"
  ].freeze

  # The rider's photo if they have one, otherwise their initial on a colour
  # picked from their name, so the same rider always gets the same colour.
  def avatar_tag(trip, size: "h-9 w-9")
    if trip.avatar.present?
      image_tag "avatars/#{trip.avatar}", alt: "", class: "#{size} shrink-0 rounded-full object-cover"
    else
      color = AVATAR_COLORS[trip.name.sum % AVATAR_COLORS.size]
      tag.span trip.name.first.upcase, "aria-hidden": true,
               class: "#{size} #{color} inline-flex shrink-0 items-center justify-center rounded-full text-sm font-semibold"
    end
  end

  # Needs are sky, offers are emerald, shared plans are violet.
  def tag_chip_class(key, tone)
    colors =
      if TagCatalog::BY_KEY.fetch(key).symmetric? then "bg-violet-50 text-violet-800 border-violet-200"
      elsif tone == :offer then "bg-emerald-50 text-emerald-800 border-emerald-200"
      else "bg-sky-50 text-sky-800 border-sky-200"
      end
    "inline-block rounded-full border px-2.5 py-0.5 text-xs #{colors}"
  end
end
