// Verifies the gateway-assertion interceptor: a valid assertion is accepted,
// one signed by a different key is rejected, a tampered payload is rejected,
// and a request with no assertion at all is rejected too — every operation on
// this contract requires sign-in, so there is no `security: []` case to cover.
//
// GATEWAY_ASSERTION_CERTIFICATE / _ISSUER / _HEADER must be exported, from the
// throwaway keypair under tests/resources, BEFORE `bal test` runs — see
// todo-api's own notes / the ballerina skill for the exact commands.

import ballerina/http;
import ballerina/test;

const string ASSERTION_HEADER = "x-jwt-assertion";

final http:Client authTestClient = check new ("http://localhost:9090");

@test:Config {}
function testValidAssertionIsAccepted() returns error? {
    string assertion = check validAssertion("auth-valid-user", "todo-items:read todo-items:write");
    http:Response res = check authTestClient->post("/me/todo-items", {title: "Buy milk"},
        {[ASSERTION_HEADER]: assertion});
    test:assertEquals(res.statusCode, 201);
}

@test:Config {}
function testAssertionFromDifferentKeyIsUnauthorized() returns error? {
    string assertion = check assertionFromWrongKey("auth-wrong-key-user", "todo-items:read");
    http:Response res = check authTestClient->get("/me/todo-items", {[ASSERTION_HEADER]: assertion});
    test:assertEquals(res.statusCode, 401);
}

@test:Config {}
function testTamperedAssertionIsUnauthorized() returns error? {
    string original = check validAssertion("auth-tamper-user", "todo-items:read");
    string tampered = check tamperedAssertion(original);
    http:Response res = check authTestClient->get("/me/todo-items", {[ASSERTION_HEADER]: tampered});
    test:assertEquals(res.statusCode, 401);
}

@test:Config {}
function testNoAssertionAtAllIsUnauthorized() returns error? {
    http:Response res = check authTestClient->get("/me/todo-items", {});
    test:assertEquals(res.statusCode, 401);
}
