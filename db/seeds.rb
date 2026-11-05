# Fictional demo trips. Names, trips and contact handles are made up. Some show
# photos of the developer's friends, used with their permission; the names
# beside them are not theirs.
#
# This runs on every boot in production (see bin/docker-entrypoint), so it must
# be safe to repeat. Each sample trip is created once and renewed with fresh
# dates after it ends, so the demo never goes stale. Trips posted by real
# riders are never touched.
today = Date.current

# name, resort, starts in (days), length (days), level, languages, looking for, can offer, contact, note
demo_trips = [
  # On the mountain now: these start in the past and renew to the same offsets.
  [ "Hana", "Niseko United", -2, 7, "advanced", %w[English Japanese], %w[ride_buddy], %w[japanese driver], "line", "Powder's been great all week. Join me for first chair." ],
  [ "Lucas", "Whistler Blackcomb", -1, 4, "intermediate", %w[English French], %w[ride_buddy lodge_mate], %w[gear], "instagram", "Here till Sunday, happy to show people around Blackcomb." ],
  [ "Jun", "Hakuba Happo-one", -3, 8, "expert", %w[English Cantonese Japanese], %w[student], %w[instructor japanese], "whatsapp", "Teaching all week, a couple of lesson slots left." ],
  [ "Ashley", "Revelstoke", 0, 5, "advanced", %w[English], %w[ride_buddy driver], [], "email", "Just arrived, looking for someone to ride the bowls with." ],
  # Upcoming trips
  [ "Nicky", "Hakuba Happo-one", 30, 5, "intermediate", %w[English Cantonese], %w[driver lodge_mate], %w[japanese], "whatsapp", "First time in Hakuba, happy to split a lodge." ],
  [ "Miles", "Hakuba Happo-one", 31, 4, "intermediate", %w[English Japanese], %w[lodge_mate ride_buddy], %w[driver idp], "line", "Renting a car from Nagano station." ],
  [ "Jason", "Hakuba Goryu", 29, 6, "advanced", %w[English Mandarin], %w[ride_buddy], %w[gear], "wechat", "Have a spare 154 board if anyone needs one." ],
  [ "Ken", "Hakuba Happo-one", 28, 10, "expert", %w[English Japanese Cantonese], %w[student], %w[instructor japanese], "whatsapp", "CASI Level 2, private lessons for beginners and intermediates." ],
  [ "Priya", "Hakuba Goryu", 32, 3, "beginner", %w[English], %w[instructor gear], [], "instagram", "Never snowboarded. Looking for a patient coach." ],
  [ "Lily", "Hakuba Happo-one", 33, 4, "beginner", %w[Cantonese English], %w[instructor ride_buddy], [], "whatsapp", "Want lessons in Cantonese if possible." ],
  [ "Daniel", "Nozawa Onsen", 30, 5, "advanced", %w[English French], %w[driver lodge_mate], %w[gear], "email", "Coming from Tokyo, no licence for Japan." ],
  [ "Cindy", "Nozawa Onsen", 29, 7, "intermediate", %w[Japanese English], %w[lodge_mate], %w[driver idp japanese], "line", "Driving up from Tokyo, two seats free." ],
  [ "Chloe", "Niseko United", 45, 7, "advanced", %w[English Cantonese], %w[ride_buddy lodge_mate], %w[idp driver], "whatsapp", "Booked a 2-bed condo in Hirafu, one room free." ],
  [ "Marcus", "Niseko United", 46, 5, "advanced", %w[English], %w[lodge_mate ride_buddy driver], [], "instagram", "Backcountry curious, solo trip." ],
  [ "Yuki", "Rusutsu", 44, 4, "expert", %w[Japanese English Mandarin], %w[student], %w[instructor japanese], "line", "Freestyle and park coaching." ],
  [ "Leo", "Rusutsu", 45, 3, "intermediate", %w[Mandarin English], %w[instructor driver], %w[gear], "wechat", "Want to learn ground tricks." ],
  [ "Ada", "Kiroro", 50, 6, "intermediate", %w[English Korean], %w[ride_buddy japanese], %w[driver idp], "email", "Flying into Sapporo, renting a car." ],
  [ "Min-jun", "Kiroro", 51, 4, "advanced", %w[Korean English], %w[driver ride_buddy], [], "instagram", "Powder days only, happy to chip in for gas." ],
  [ "Megan", "Furano", 52, 5, "beginner", %w[English Cantonese], %w[instructor lodge_mate], [], "whatsapp", "Family-friendly trip with my sister." ],
  [ "Tom", "Myoko Akakura", 60, 8, "advanced", %w[English], %w[japanese ride_buddy], %w[driver idp], "email", "Long trip, flexible dates." ],
  [ "Kana", "Myoko Akakura", 61, 4, "intermediate", %w[Japanese English], %w[ride_buddy driver], %w[japanese], "line", "Local, can show the good tree runs." ],
  [ "Ivan", "Naeba", 62, 3, "beginner", %w[English Mandarin], %w[instructor], [], "wechat", "Short weekend trip from Tokyo." ],
  [ "Elena", "Gala Yuzawa", 63, 2, "intermediate", %w[English French], %w[ride_buddy gear], [], "instagram", "Day trip by shinkansen, need rental advice." ],
  [ "Ryan", "Whistler Blackcomb", 20, 4, "advanced", %w[English Cantonese], %w[ride_buddy lodge_mate], %w[driver], "whatsapp", "Driving up from Vancouver Friday morning." ],
  [ "Sophie", "Whistler Blackcomb", 21, 3, "intermediate", %w[English French], %w[driver lodge_mate], %w[gear], "instagram", "No car, can split gas and parking." ],
  [ "Arjun", "Whistler Blackcomb", 19, 6, "expert", %w[English], %w[student], %w[instructor driver], "email", "CASI Level 3, freeride and steeps." ],
  [ "Nicole", "Whistler Blackcomb", 22, 2, "beginner", %w[Mandarin English], %w[instructor ride_buddy], [], "wechat", "First season, want to learn carving." ],
  [ "Noah", "Revelstoke", 35, 5, "expert", %w[English], %w[lodge_mate ride_buddy], %w[driver], "email", "Splitting an Airbnb, one spot left." ],
  [ "Fiona", "Revelstoke", 36, 4, "advanced", %w[English Cantonese], %w[driver ride_buddy], %w[gear], "whatsapp", "Flying into Kelowna." ],
  [ "Owen", "Sun Peaks", 40, 3, "intermediate", %w[English], %w[ride_buddy], [], "instagram", "Spring break trip, chill pace." ],
  [ "Isabelle", "Big White", 41, 5, "beginner", %w[English French], %w[instructor lodge_mate], [], "email", "Booked a ski-in condo." ],
  [ "Kai", "Banff Sunshine", 55, 4, "advanced", %w[English Japanese], %w[ride_buddy lodge_mate], %w[driver japanese], "line", "Road trip from Calgary." ],
  [ "Zoe", "Lake Louise", 56, 3, "intermediate", %w[English Mandarin], %w[driver ride_buddy], [], "wechat", "Staying in Banff town." ],
  [ "Ben", "Lake Louise", 55, 5, "expert", %w[English], %w[student], %w[instructor driver gear], "email", "Can lend boots and goggles to students." ]
].freeze

# Photo for each sample rider, from app/assets/images/avatars. Riders not
# listed get an initial avatar, the same as real riders.
demo_avatars = {
  "Hana" => "avatar-05.jpg", "Lucas" => "avatar-13.jpg", "Jun" => "avatar-17.jpg", "Ashley" => "avatar-03.jpg",
  "Nicky" => "avatar-02.jpg", "Miles" => "avatar-11.jpg", "Jason" => "avatar-14.jpg", "Priya" => "avatar-10.jpg",
  "Lily" => "avatar-04.jpg", "Daniel" => "avatar-08.jpg", "Cindy" => "avatar-06.jpg", "Chloe" => "avatar-12.jpg",
  "Marcus" => "avatar-09.jpg", "Megan" => "avatar-07.jpg", "Ryan" => "avatar-15.jpg", "Sophie" => "avatar-16.jpg",
  "Nicole" => "avatar-18.jpg", "Noah" => "avatar-01.jpg"
}.freeze

Trip.transaction do
  Trip.demo.where.not(name: demo_trips.map(&:first)).delete_all

  demo_trips.each do |name, resort, starts_in, length, level, languages, looking_for, offering, contact_method, note|
    trip = Trip.demo.find_or_initialize_by(name:)
    trip.assign_attributes(
      resort:, skill_level: level, languages:, looking_for:, offering:, contact_method:, note:,
      party_size: 1, contact_handle: "demo-only (#{name.parameterize})", avatar: demo_avatars[name]
    )
    if trip.new_record? || trip.ends_on < today
      trip.starts_on = today + starts_in
      trip.ends_on = today + starts_in + length - 1
    end
    trip.save! if trip.changed?
  end
end

puts "#{Trip.demo.count} sample trips ready"
