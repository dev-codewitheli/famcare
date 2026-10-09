-- Who a gate alert rings: the sender picks (e.g. not the person at school or work).
-- Alerts from before this table have no rows here and count as ringing everyone else.
create table gate_alert_recipients (
    alert_id  uuid not null references gate_alerts (id) on delete cascade,
    member_id uuid not null references members (id),
    primary key (alert_id, member_id)
);
