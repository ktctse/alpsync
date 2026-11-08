# Alpsync

**Live: [alpsync.onrender.com](https://alpsync.onrender.com)**

Find your ski and snowboard crew. Skiers and snowboarders post a trip (resort, dates, languages,
riding level) with two sets of tags: what they're **looking for** and what they **can offer**.
Alpsync matches them with riders on the same dates who fit, whether that's a driver, a lodge mate,
or a coach, and says why each match was made.

Built with Rails 8.1, Hotwire, Tailwind CSS and Postgres.

## The problem

Riders heading to Japan or the BC interior already look for each other, mostly in WhatsApp, WeChat
and LINE groups and on boards that list everyone's phone number publicly. Posts get buried within
hours, there's no way to filter by what you actually need, and contact details are open to anyone
who scrolls past.

## How matching works

Matching lives in one class, [`app/models/matcher.rb`](app/models/matcher.rb), with tests in
[`test/models/matcher_test.rb`](test/models/matcher_test.rb).

1. **Hard filters, in SQL.** Same region, overlapping dates, and at least one shared language
   (Postgres array overlap, `languages && ARRAY[...]`). A match you can't talk to isn't a match.
2. **Scoring, in Ruby.** Tags come in two kinds ([`app/models/tag_catalog.rb`](app/models/tag_catalog.rb)):
   - *Complementary* (Instructor, Student, Driver, International Driving Permit, Gear to lend,
     Japanese speaker): my "looking for" against your "can offer", in both directions.
   - *Symmetric* (Lodge mate, Ride buddy): both riders want the same thing, so they match when
     both picked it.

   Points: 3 per need the other rider covers (each way), 2 per shared plan, 2 bonus when both
   riders get something (a *mutual match*), 1 for the same resort, 1 for a similar level when
   looking for a ride buddy.
3. **Reasons.** Every point comes with a plain-English line on the match card, such as
   "They can offer what you need: Driver".

## Paste-to-post

Riders already write their plans in group chats, so the new-trip page lets them paste that
message and have Claude fill in the form
([`app/models/trip_draft.rb`](app/models/trip_draft.rb)).

- One Claude API call (Claude Opus 5.5, low effort) with a strict JSON schema whose resorts,
  tags, languages and contact apps are the form's own options. Every value is checked again in
  Ruby before it touches the form.
- The form is refilled with a Turbo Stream for the rider to review. Nothing is posted
  automatically, and the pasted message is never stored.
- The pasted text is treated as data, not instructions, and Claude can only answer in the schema.
- Each visitor gets 5 tries a minute and 30 a day, and messages are capped at 1,500 characters,
  so a public page can't run up the API bill.
- If `ANTHROPIC_API_KEY` isn't set, the paste box doesn't show and the form works as before.

## Decision log

| Decision | Why | Trade-off |
|---|---|---|
| Have/want tags instead of swiping | Riders need specific things (a car, a coach, a roommate), not a vibe check. Tags make needs explicit and matchable. | Fixed vocabulary; unusual needs go in the free-text note. |
| Rule-based scoring, not AI | Matches must be explainable and predictable; every point maps to a reason the rider can see. | Weights are hand-picked; they'd be tuned from data (contact rate per match) in a real launch. |
| No accounts; private edit link | Posting a trip should take a minute. The edit token is the key, and opening the link remembers the browser. | Lose the link and you can't edit; no notifications yet. |
| Contact shown only to riders who posted | Stops anonymous scraping of phone numbers and makes the board reciprocal. | A small hurdle for people who just want to browse and message. |
| Region-level matching | Riders at Hakuba Happo-one and Hakuba Goryu can easily meet up. Same resort only breaks ties. | A big region (BC) can pair riders who are hours apart. |
| Rails 8 monolith with Hotwire | One codebase, server-rendered pages, fast to build and easy to reason about. | Less suited to very rich client-side UI (maps, drag and drop), which this product doesn't need. |
| AI fills the form; the rider posts | Cuts posting to a paste for people who've already written their plan in a chat, while keeping them in control of what goes public. | One extra click versus auto-posting, and an API cost per paste (rate-limited). |

## What I'd measure

- Trips posted per week, and the share with at least one match
- Match to contact-reveal rate (are the matches useful?)
- Time from posting to first match
- Repeat posting next trip (did it work last time?)
- Paste-to-post: share of pastes that end in a posted trip, and how many fields riders change
  after Claude fills them in

## What's next

- Email or push notification when a new match appears (Turbo Streams for live updates)
- Instructor profiles with lesson booking through Shopify checkout
- Reporting and moderation for spam posts

## Running it locally

Everything runs in Docker, so only Docker Desktop is needed.

```sh
docker compose up -d db
docker compose run --rm web bin/rails db:create db:migrate db:seed
docker compose up web        # then open http://localhost:3100
docker compose run --rm -e RAILS_ENV=test web bin/rails test
```

The seed data in [`db/seeds.rb`](db/seeds.rb) is fictional. No real people or contact details.
Demo trips are flagged `demo` and shown with a "Sample" label. They refresh themselves on boot once
most have ended, and real riders' trips are never touched.

## Deploying

Hosted on [Render](https://render.com) from [`render.yaml`](render.yaml), which creates the web
service (built from the [`Dockerfile`](Dockerfile)) and a Postgres database together.

1. Push this repository to GitHub.
2. In Render: **New > Blueprint**, pick the repository, and apply.
3. Render builds the image, then on boot `bin/docker-entrypoint` migrates the database and seeds the
   demo trips. The health check is `/up`.

`SECRET_KEY_BASE` is generated by Render, so no secrets live in the repository. Render's free tier
sleeps when idle (the first visit after a quiet spell takes a few seconds) and its free database
expires after a set period; move both to paid instances before relying on the link.

## Credits

- The Everest motion graphic at the bottom of the home page
  ([`everest_controller.js`](app/javascript/controllers/everest_controller.js)) is inspired by the
  animated logo on [Raide Research](https://raideresearch.com)'s website. The code and drawings
  here are original.
- Banner photos are the developer's own. Sample riders' photos are of friends, used with their
  permission.
