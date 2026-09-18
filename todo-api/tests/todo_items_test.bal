// CRUD + ownership + validation behavior, against the in-memory store
// substituted by tests/mock_store.bal. Each test uses its own caller subject
// so tests never interfere with one another's rows.

import ballerina/http;
import ballerina/test;

type TestTodoItem record {
    string id;
    string title;
    boolean done;
    string? dueDate?;
    string createdAt;
    string updatedAt;
};

function callerHeaders(string userId) returns map<string|string[]>|error {
    string assertion = check validAssertion(userId, "todo-items:read todo-items:write");
    return {[ASSERTION_HEADER]: assertion};
}

function createAsCaller(string userId, string title, string? dueDate = ()) returns TestTodoItem|error {
    map<string|string[]> headers = check callerHeaders(userId);
    json body = dueDate is string ? {title, dueDate} : {title};
    http:Response res = check authTestClient->post("/me/todo-items", body, headers);
    test:assertEquals(res.statusCode, 201);
    json payload = check res.getJsonPayload();
    return payload.cloneWithType(TestTodoItem);
}

@test:Config {}
function testCreateThenGetOwnItem() returns error? {
    string userId = "crud-owner-1";
    TestTodoItem created = check createAsCaller(userId, "Buy milk");
    test:assertEquals(created.title, "Buy milk");
    test:assertEquals(created.done, false);

    map<string|string[]> headers = check callerHeaders(userId);
    http:Response res = check authTestClient->get(string `/me/todo-items/${created.id}`, headers);
    test:assertEquals(res.statusCode, 200);
    json payload = check res.getJsonPayload();
    TestTodoItem fetched = check payload.cloneWithType(TestTodoItem);
    test:assertEquals(fetched.id, created.id);
    test:assertEquals(fetched.title, "Buy milk");
}

@test:Config {}
function testCreateWithEmptyTitleIsBadRequest() returns error? {
    map<string|string[]> headers = check callerHeaders("crud-bad-create");
    http:Response res = check authTestClient->post("/me/todo-items", {title: "   "}, headers);
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testListOnlyReturnsCallersOwnItems() returns error? {
    string owner = "crud-list-owner";
    string other = "crud-list-other";
    TestTodoItem mine = check createAsCaller(owner, "Owner's item");
    TestTodoItem theirs = check createAsCaller(other, "Other user's item");

    map<string|string[]> headers = check callerHeaders(owner);
    http:Response res = check authTestClient->get("/me/todo-items?limit=100&offset=0", headers);
    test:assertEquals(res.statusCode, 200);
    json payload = check res.getJsonPayload();
    map<json> envelope = <map<json>>payload;
    json[] data = <json[]>envelope["data"];
    boolean sawMine = false;
    foreach json entry in data {
        TestTodoItem item = check entry.cloneWithType(TestTodoItem);
        test:assertFalse(item.id == theirs.id, "the other caller's item must never appear in this caller's list");
        if item.id == mine.id {
            sawMine = true;
        }
    }
    test:assertTrue(sawMine, "the caller's own item must appear in their list");
}

@test:Config {}
function testGetOtherUsersItemIsNotFound() returns error? {
    TestTodoItem item = check createAsCaller("crud-get-owner", "Private item");
    map<string|string[]> otherHeaders = check callerHeaders("crud-get-intruder");
    http:Response res = check authTestClient->get(string `/me/todo-items/${item.id}`, otherHeaders);
    test:assertEquals(res.statusCode, 404);
}

@test:Config {}
function testUpdateOwnItem() returns error? {
    string userId = "crud-update-owner";
    TestTodoItem item = check createAsCaller(userId, "Original title");
    map<string|string[]> headers = check callerHeaders(userId);
    http:Response res = check authTestClient->patch(string `/me/todo-items/${item.id}`,
        {title: "Updated title", done: true}, headers);
    test:assertEquals(res.statusCode, 200);
    json payload = check res.getJsonPayload();
    TestTodoItem updated = check payload.cloneWithType(TestTodoItem);
    test:assertEquals(updated.title, "Updated title");
    test:assertEquals(updated.done, true);
}

@test:Config {}
function testUpdateWithEmptyTitleIsBadRequest() returns error? {
    string userId = "crud-update-bad";
    TestTodoItem item = check createAsCaller(userId, "Keep me");
    map<string|string[]> headers = check callerHeaders(userId);
    http:Response res = check authTestClient->patch(string `/me/todo-items/${item.id}`, {title: ""}, headers);
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testUpdateOtherUsersItemIsNotFound() returns error? {
    TestTodoItem item = check createAsCaller("crud-update-owner-2", "Not yours");
    map<string|string[]> intruderHeaders = check callerHeaders("crud-update-intruder");
    http:Response res = check authTestClient->patch(string `/me/todo-items/${item.id}`, {done: true}, intruderHeaders);
    test:assertEquals(res.statusCode, 404);
}

@test:Config {}
function testUpdateNonExistentItemIsNotFound() returns error? {
    map<string|string[]> headers = check callerHeaders("crud-update-missing");
    http:Response res = check authTestClient->patch("/me/todo-items/does-not-exist", {done: true}, headers);
    test:assertEquals(res.statusCode, 404);
}

@test:Config {}
function testDeleteOwnItemThenNotFound() returns error? {
    string userId = "crud-delete-owner";
    TestTodoItem item = check createAsCaller(userId, "Delete me");
    map<string|string[]> headers = check callerHeaders(userId);
    http:Response deleteRes = check authTestClient->delete(string `/me/todo-items/${item.id}`, (), headers);
    test:assertEquals(deleteRes.statusCode, 204);

    http:Response getRes = check authTestClient->get(string `/me/todo-items/${item.id}`, headers);
    test:assertEquals(getRes.statusCode, 404);
}

@test:Config {}
function testDeleteOtherUsersItemIsNotFound() returns error? {
    TestTodoItem item = check createAsCaller("crud-delete-owner-2", "Still not yours");
    map<string|string[]> intruderHeaders = check callerHeaders("crud-delete-intruder");
    http:Response res = check authTestClient->delete(string `/me/todo-items/${item.id}`, (), intruderHeaders);
    test:assertEquals(res.statusCode, 404);
}

@test:Config {}
function testDeleteNonExistentItemIsNotFound() returns error? {
    map<string|string[]> headers = check callerHeaders("crud-delete-missing");
    http:Response res = check authTestClient->delete("/me/todo-items/does-not-exist", (), headers);
    test:assertEquals(res.statusCode, 404);
}

@test:Config {}
function testListPagination() returns error? {
    string userId = "crud-page-owner";
    TestTodoItem _ = check createAsCaller(userId, "First");
    TestTodoItem _ = check createAsCaller(userId, "Second");
    map<string|string[]> headers = check callerHeaders(userId);

    http:Response page1Res = check authTestClient->get("/me/todo-items?limit=1&offset=0", headers);
    test:assertEquals(page1Res.statusCode, 200);
    map<json> page1 = <map<json>>check page1Res.getJsonPayload();
    int count = check page1["count"].ensureType();
    test:assertTrue(count >= 2, "count must include every item the caller owns, not just the page");
    json[] page1Data = <json[]>page1["data"];
    test:assertEquals(page1Data.length(), 1, "a page must not exceed the requested limit");
    test:assertTrue(page1["next"] is string, "a further page must be linked when more rows remain");

    http:Response page2Res = check authTestClient->get("/me/todo-items?limit=1&offset=1", headers);
    map<json> page2 = <map<json>>check page2Res.getJsonPayload();
    test:assertTrue(page2["previous"] is string, "the second page must link back to the first");
}
