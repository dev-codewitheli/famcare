-- "On my way (~10 min)" heads-ups, so someone can head to the gate before the ring.
create table arrival_notices (
    id          uuid primary key,
    family_id   uuid                     not null references families (id),
    member_id   uuid                     not null references members (id),
    eta_minutes integer                  not null,
    created_at  timestamp with time zone not null
);
create index idx_arrival_notices_family on arrival_notices (family_id, created_at);

-- Recent activity lists the newest gate alerts per family.
create index idx_gate_alerts_family_created on gate_alerts (family_id, created_at);
