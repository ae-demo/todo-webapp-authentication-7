// Small helpers for the error shapes every operation may answer with.

function unauthorizedError() returns ErrorUnauthorized => {
    body: {code: 401, message: "Missing or invalid sign-in"}
};

function notFoundError() returns ErrorNotFound => {
    body: {code: 404, message: "No such todo item for this caller"}
};

function badRequestError(string message) returns ErrorBadRequest => {
    body: {code: 400, message}
};

function toApiItem(TodoItemRecord r) returns TodoItem => {
    id: r.id,
    title: r.title,
    done: r.done,
    dueDate: r.dueDate,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt
};

function pageLink(int 'limit, int offset) returns string => string `/me/todo-items?limit=${'limit}&offset=${offset}`;

function previousOffset(int offset, int 'limit) returns int {
    int prev = offset - 'limit;
    return prev < 0 ? 0 : prev;
}
