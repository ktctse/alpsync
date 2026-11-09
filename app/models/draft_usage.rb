# A site-wide daily allowance for paste-to-post. Each pasted message is a paid
# Claude API call, and per-visitor limits can be dodged by switching networks,
# so this caps the total for everyone. The count lives in Postgres so it
# survives restarts (Render's free server sleeps when idle, which wipes the
# per-visitor limits kept in the cache).
class DraftUsage < ApplicationRecord
  class_attribute :daily_limit, default: Integer(ENV.fetch("DRAFTS_PER_DAY", 50))

  # Uses one of today's drafts. False once today's allowance is spent.
  def self.take
    used = upsert({ day: Date.current, count: 1 }, unique_by: :day, returning: :count,
                  on_duplicate: Arel.sql("count = draft_usages.count + 1"))
    used.rows.first.first <= daily_limit
  end
end
