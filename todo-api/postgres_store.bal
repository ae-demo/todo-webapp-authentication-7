// The production TodoStore, backed by the todo-db Postgres database.

import ballerina/sql;
import ballerina/time;
import ballerina/uuid;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;

// The raw row shape a query returns, aliased to camelCase in the SQL itself
// so this record can use ordinary field naming.
type TodoRow record {|
    string id;
    string userId;
    string title;
    boolean done;
    string? dueDate;
    time:Utc createdAt;
    time:Utc updatedAt;
|};

class PostgresTodoStore {
    *TodoStore;

    private final postgresql:Client dbClient;

    function init(postgresql:Client dbClient) returns error? {
        self.dbClient = dbClient;
        _ = check self.dbClient->execute(`
            CREATE TABLE IF NOT EXISTS todo_items (
                id VARCHAR(64) PRIMARY KEY,
                user_id VARCHAR(128) NOT NULL,
                title VARCHAR(500) NOT NULL,
                done BOOLEAN NOT NULL DEFAULT FALSE,
                due_date VARCHAR(10),
                created_at TIMESTAMPTZ NOT NULL,
                updated_at TIMESTAMPTZ NOT NULL
            )
        `);
        _ = check self.dbClient->execute(`
            CREATE INDEX IF NOT EXISTS idx_todo_items_user_id ON todo_items (user_id)
        `);
    }

    public function list(string userId, int 'limit, int offset) returns [TodoItemRecord[], int]|error {
        int total = check self.dbClient->queryRow(`SELECT COUNT(*) FROM todo_items WHERE user_id = ${userId}`);
        stream<TodoRow, sql:Error?> rows = self.dbClient->query(`
            SELECT id, user_id AS "userId", title, done, due_date AS "dueDate",
                   created_at AS "createdAt", updated_at AS "updatedAt"
            FROM todo_items
            WHERE user_id = ${userId}
            ORDER BY created_at DESC, id DESC
            LIMIT ${'limit} OFFSET ${offset}
        `);
        TodoItemRecord[] items = [];
        check from TodoRow row in rows
            do {
                items.push(toRecord(row));
            };
        return [items, total];
    }

    public function get(string userId, string itemId) returns TodoItemRecord|error? {
        TodoRow|sql:Error row = self.dbClient->queryRow(`
            SELECT id, user_id AS "userId", title, done, due_date AS "dueDate",
                   created_at AS "createdAt", updated_at AS "updatedAt"
            FROM todo_items
            WHERE id = ${itemId} AND user_id = ${userId}
        `);
        if row is sql:NoRowsError {
            return ();
        }
        if row is sql:Error {
            return row;
        }
        return toRecord(row);
    }

    public function create(string userId, string title, string? dueDate) returns TodoItemRecord|error {
        string id = uuid:createRandomUuid();
        time:Utc now = time:utcNow();
        _ = check self.dbClient->execute(`
            INSERT INTO todo_items (id, user_id, title, done, due_date, created_at, updated_at)
            VALUES (${id}, ${userId}, ${title}, false, ${dueDate}, ${now}, ${now})
        `);
        string nowString = time:utcToString(now);
        return {
            id,
            userId,
            title,
            done: false,
            dueDate,
            createdAt: nowString,
            updatedAt: nowString
        };
    }

    public function update(string userId, string itemId, TodoUpdateFields fields) returns TodoItemRecord|error? {
        TodoItemRecord|error? existing = self.get(userId, itemId);
        if existing is () {
            return ();
        }
        if existing is error {
            return existing;
        }
        string newTitle = fields.titleProvided && fields.title is string ? <string>fields.title : existing.title;
        string? newDueDate = fields.dueDateProvided ? fields.dueDate : existing.dueDate;
        boolean newDone = fields.doneProvided && fields.done is boolean ? <boolean>fields.done : existing.done;
        time:Utc now = time:utcNow();
        _ = check self.dbClient->execute(`
            UPDATE todo_items
            SET title = ${newTitle}, due_date = ${newDueDate}, done = ${newDone}, updated_at = ${now}
            WHERE id = ${itemId} AND user_id = ${userId}
        `);
        return {
            id: itemId,
            userId,
            title: newTitle,
            done: newDone,
            dueDate: newDueDate,
            createdAt: existing.createdAt,
            updatedAt: time:utcToString(now)
        };
    }

    public function delete(string userId, string itemId) returns boolean|error {
        sql:ExecutionResult result = check self.dbClient->execute(`
            DELETE FROM todo_items WHERE id = ${itemId} AND user_id = ${userId}
        `);
        int? affected = result.affectedRowCount;
        return affected is int && affected > 0;
    }
}

function toRecord(TodoRow row) returns TodoItemRecord => {
    id: row.id,
    userId: row.userId,
    title: row.title,
    done: row.done,
    dueDate: row.dueDate,
    createdAt: time:utcToString(row.createdAt),
    updatedAt: time:utcToString(row.updatedAt)
};

// Wrapped in its own function so a test can `@test:Mock` it and substitute a
// database-free TodoStore, per the ballerina skill's test-mocking pattern.
function createStore() returns TodoStore|error {
    postgresql:Client dbClient = check new (
        host = dbHost,
        username = dbUser,
        password = dbPassword,
        database = dbName,
        port = dbPort
    );
    return new PostgresTodoStore(dbClient);
}

final TodoStore todoStore = check createStore();
