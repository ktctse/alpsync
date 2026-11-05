module ApplicationHelper
  FIELD_CLASS = "w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-800 " \
                "focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-200".freeze

  def field_class = FIELD_CLASS

  # "Jan 10–14", or "Jan 30–Feb 3" when the trip crosses a month.
  def trip_dates(trip)
    starts, ends = trip.starts_on, trip.ends_on
    return starts.strftime("%b %-d") if starts == ends

    finish = starts.month == ends.month ? ends.strftime("%-d") : ends.strftime("%b %-d")
    "#{starts.strftime('%b %-d')}–#{finish}"
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
