-- "Time's up — are you at the gate?" is sent once per heads-up.
alter table arrival_notices add column due_notified_at timestamp with time zone;

-- Who tapped "Got it" on a heads-up. Goes away with the notice.
create table arrival_seen (
    notice_id uuid                     not null references arrival_notices (id) on delete cascade,
    member_id uuid                     not null references members (id),
    seen_at   timestamp with time zone not null,
    primary key (notice_id, member_id)
);

-- Removed members are kept (soft delete) so past gate activity still shows their nickname.
alter table members add column removed_at timestamp with time zone;
