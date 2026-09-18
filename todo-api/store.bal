// The persistence contract for todo items, decoupled from Postgres so the
// business rules (ownership, validation, 404-vs-not-found) are testable
// without a database. `PostgresTodoStore` (postgres_store.bal) is the only
// production implementation.

# The internal, storage-side shape of a todo item. `userId` is always the
# gateway assertion's `sub` — never a client-supplied value.
public type TodoItemRecord record {|
    string id;
    string userId;
    string title;
    boolean done;
    string? dueDate;
    string createdAt;
    string updatedAt;
|};

# Fields a caller wants to change on PATCH. A field whose `*Provided` flag is
# false was absent from the request body and must be left untouched — this is
# what lets `dueDate` be cleared with an explicit `null` while an absent
# `dueDate` leaves it alone.
public type TodoUpdateFields record {|
    string? title = ();
    boolean titleProvided = false;
    string? dueDate = ();
    boolean dueDateProvided = false;
    boolean? done = ();
    boolean doneProvided = false;
|};

# Persists todo items, always scoped to one caller's own rows.
public type TodoStore object {
    # The caller's items, newest first, with the total count matching the caller.
    public function list(string userId, int 'limit, int offset) returns [TodoItemRecord[], int]|error;
    # A single item, or `()` when it does not exist or is not the caller's.
    public function get(string userId, string itemId) returns TodoItemRecord|error?;
    # Creates a new item owned by `userId`.
    public function create(string userId, string title, string? dueDate) returns TodoItemRecord|error;
    # Updates an existing item, or `()` when it does not exist or is not the caller's.
    public function update(string userId, string itemId, TodoUpdateFields fields) returns TodoItemRecord|error?;
    # true when a row owned by `userId` was deleted; false when there was none to delete.
    public function delete(string userId, string itemId) returns boolean|error;
};
