-- Portable SQL: runs on PostgreSQL (production) and H2 (demo mode and tests).

create table families (
    id          uuid primary key,
    name        varchar(80)              not null,
    invite_code varchar(6)               not null unique,
    created_at  timestamp with time zone not null
);

-- Deliberately minimal: a nickname and the identity-provider UID. No email, phone, or photo.
create table members (
    id           uuid primary key,
    family_id    uuid                     not null references families (id),
    auth_uid     varchar(128)             not null unique,
    display_name varchar(40)              not null,
    role         varchar(16)              not null,
    joined_at    timestamp with time zone not null
);
create index idx_members_family on members (family_id);

-- FCM registration tokens. One member can have several phones; a token belongs to one member.
create table devices (
    push_token varchar(512) primary key,
    member_id  uuid                     not null references members (id),
    updated_at timestamp with time zone not null
);
create index idx_devices_member on devices (member_id);

create table gate_alerts (
    id              uuid primary key,
    family_id       uuid                     not null references families (id),
    sender_id       uuid                     not null references members (id),
    created_at      timestamp with time zone not null,
    status          varchar(16)              not null,
    ring_count      integer                  not null,
    last_rung_at    timestamp with time zone not null,
    acknowledged_by uuid references members (id),
    resolved_at     timestamp with time zone
);
create index idx_gate_alerts_status on gate_alerts (status, family_id);
