// Configuration, read from the environment in one place. Every value has a
// safe built-in default so the service starts with no environment variables
// set at all; the platform's todo-db wiring overrides them at deploy time.

import ballerina/os;

configurable string dbHostEnv = os:getEnv("TODO_DB_HOST");
configurable string dbPortEnv = os:getEnv("TODO_DB_PORT");
configurable string dbUserEnv = os:getEnv("TODO_DB_USER");
configurable string dbPasswordEnv = os:getEnv("TODO_DB_PASSWORD");
configurable string dbNameEnv = os:getEnv("TODO_DB_DBNAME");

final string dbHost = dbHostEnv == "" ? "localhost" : dbHostEnv;
final int dbPort = parsePort(dbPortEnv);
final string dbUser = dbUserEnv == "" ? "postgres" : dbUserEnv;
final string dbPassword = dbPasswordEnv;
final string dbName = dbNameEnv == "" ? "todo" : dbNameEnv;

# Parses the TODO_DB_PORT value, falling back to Postgres' default port when
# it is unset or not a number.
#
# + raw - the raw environment value
# + return - the port to connect on
function parsePort(string raw) returns int {
    if raw == "" {
        return 5432;
    }
    int|error parsed = int:fromString(raw);
    if parsed is int {
        return parsed;
    }
    return 5432;
}
