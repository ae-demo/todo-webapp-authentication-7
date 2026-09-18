# Domain Model

A signed-in user owns a personal list of todo items. Each item belongs to
exactly one user, identified by the sign-in subject.

```mermaid
erDiagram
    USER ||--o{ TODO_ITEM : owns

    USER {
        string id PK
        string email
    }
    TODO_ITEM {
        string id PK
        string userId FK
        string title
        boolean done
        date dueDate
        datetime createdAt
        datetime updatedAt
    }
```

`USER` is not stored by this system — it is the identity Thunder asserts on
every request (the token's `sub`). `TODO_ITEM` is the one persisted entity,
scoped to its owning user on every read and write.