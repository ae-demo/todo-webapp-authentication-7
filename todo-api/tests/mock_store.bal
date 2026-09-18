// A database-free TodoStore, substituted for the real Postgres-backed one via
// `@test:Mock` on `createStore()` (postgres_store.bal) — the pattern the
// ballerina skill's tests.md names: wrap a connector's construction in a
// small init function so a test can replace it. This lets the HTTP tests
// exercise the real service (routing, gateway-assertion interceptor,
// ownership scoping, validation) without a database.

import ballerina/test;
import ballerina/time;

class InMemoryTodoStore {
    *TodoStore;

    private map<TodoItemRecord> rows = {};
    private int seq = 0;

    public function list(string userId, int 'limit, int offset) returns [TodoItemRecord[], int]|error {
        TodoItemRecord[] all = from TodoItemRecord r in self.rows.toArray()
            where r.userId == userId
            order by r.createdAt descending
            select r;
        int total = all.length();
        if offset >= total {
            return [[], total];
        }
        int end = offset + 'limit;
        return [all.slice(offset, end > total ? total : end), total];
    }

    public function get(string userId, string itemId) returns TodoItemRecord|error? {
        TodoItemRecord? row = self.rows[itemId];
        if row is () || row.userId != userId {
            return ();
        }
        return row;
    }

    public function create(string userId, string title, string? dueDate) returns TodoItemRecord|error {
        self.seq += 1;
        string id = string `item-${self.seq}`;
        string ts = string `${time:utcToString(time:utcNow())}-${self.seq}`;
        TodoItemRecord item = {id, userId, title, done: false, dueDate, createdAt: ts, updatedAt: ts};
        self.rows[id] = item;
        return item;
    }

    public function update(string userId, string itemId, TodoUpdateFields fields) returns TodoItemRecord|error? {
        TodoItemRecord? existing = self.rows[itemId];
        if existing is () || existing.userId != userId {
            return ();
        }
        self.seq += 1;
        string title = fields.titleProvided && fields.title is string ? <string>fields.title : existing.title;
        string? dueDate = fields.dueDateProvided ? fields.dueDate : existing.dueDate;
        boolean done = fields.doneProvided && fields.done is boolean ? <boolean>fields.done : existing.done;
        TodoItemRecord updated = {
            id: itemId,
            userId,
            title,
            done,
            dueDate,
            createdAt: existing.createdAt,
            updatedAt: string `${time:utcToString(time:utcNow())}-${self.seq}`
        };
        self.rows[itemId] = updated;
        return updated;
    }

    public function delete(string userId, string itemId) returns boolean|error {
        TodoItemRecord? existing = self.rows[itemId];
        if existing is () || existing.userId != userId {
            return false;
        }
        _ = self.rows.remove(itemId);
        return true;
    }
}

@test:Mock {
    functionName: "createStore"
}
function mockCreateStore() returns TodoStore|error {
    return new InMemoryTodoStore();
}
