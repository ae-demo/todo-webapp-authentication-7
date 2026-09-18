# Todo Webapp with Authentication — PRD

## Problem Statement

People who want to keep track of the tasks they need to do often reach for
sticky notes, generic notes apps, or nothing at all — none of which are
private to them, accessible from anywhere they sign in, or reliably saved.
There is no lightweight, personal place to keep a todo list that persists
across sessions and devices and that only they can see.

## Solution

A simple web application where a signed-in user keeps their own list of todo
items — adding, completing, editing and removing tasks — with everything
saved to a database so their list is exactly as they left it the next time
they sign in, from any device.

## Actors

- **User** — signs in and manages their own todo items. Every user sees only
their own todos; there is no administrative or shared view.

## User Stories

1. As a user, I want to sign in through single sign-on, so that I have a
private, secure account without managing a separate password for this app.
2. As a user, I want to add a todo item with a title and an optional due
date, so that I can capture a task I need to do.
3. As a user, I want to see the list of my todo items, so that I can review
what is outstanding and what is already done.
4. As a user, I want to mark a todo item as done or not done, so that I can
track my progress.
5. As a user, I want to edit a todo item's title or due date, so that I can
correct or update it as things change.
6. As a user, I want to delete a todo item, so that I can remove a task I no
longer need to track.

## Product Decisions

- Sign-in is via SSO through Thunder, the platform identity provider — every
web app in this organization signs users in this way (org default).
- Todo items are persisted in a database so a user's list survives across
sessions and devices.
- Todos are strictly private: a user only ever sees and manages their own
items. There is no sharing or collaboration between users.
- There is no Administrator actor or account-management surface in this
product; account lifecycle is handled by the platform's SSO.
- No third-party services (e.g. email, notifications, reminders) are used by
this product.

## Out of Scope

- Sharing or collaborating on todo items or lists between users.
- Reminder notifications (email, push, or otherwise) for due dates.
- An administrator role or any cross-user management view.
- Mobile native apps — this is a web application only.
- Categories, tags, priority levels, or free-text notes on a todo item.
- Filtering or sorting the todo list — items are shown in one plain list.

## Open Questions

None at this time.

## Further Notes

None.

