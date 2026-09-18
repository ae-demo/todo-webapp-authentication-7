// Mints gateway-signed assertions with throwaway RSA keypairs (tests/resources)
// so no test ever talks to a real gateway or IdP.

import ballerina/crypto;
import ballerina/jwt;
import ballerina/lang.array;

const string TEST_ISSUER = "test-gateway";
const string VALID_KEY_FILE = "tests/resources/valid-private.pem";
const string OTHER_KEY_FILE = "tests/resources/other-private.pem";

# Mints an assertion signed with the throwaway key that matches
# GATEWAY_ASSERTION_CERTIFICATE — a verifiable, valid assertion.
#
# + subject - the `sub` to carry
# + scope - the space-separated `scope` claim
# + return - the signed JWT
function validAssertion(string subject, string scope) returns string|error {
    crypto:PrivateKey key = check crypto:decodeRsaPrivateKeyFromKeyFile(VALID_KEY_FILE);
    return issueAssertion(key, subject, scope);
}

# Mints an assertion signed with a DIFFERENT private key — one whose public
# half was never published as GATEWAY_ASSERTION_CERTIFICATE, so it must fail
# verification.
#
# + subject - the `sub` to carry
# + scope - the space-separated `scope` claim
# + return - the signed JWT
function assertionFromWrongKey(string subject, string scope) returns string|error {
    crypto:PrivateKey key = check crypto:decodeRsaPrivateKeyFromKeyFile(OTHER_KEY_FILE);
    return issueAssertion(key, subject, scope);
}

function issueAssertion(crypto:PrivateKey key, string subject, string scope) returns string|error {
    jwt:IssuerConfig config = {
        issuer: TEST_ISSUER,
        username: subject,
        expTime: 300,
        customClaims: {"scope": scope},
        signatureConfig: {
            algorithm: jwt:RS256,
            config: key
        }
    };
    return jwt:issue(config);
}

# Edits the payload of an already-signed JWT without re-signing it — the
# "signed, then tampered" case. The signature segment is left untouched, so it
# no longer matches the (changed) payload and verification must fail.
#
# + token - a validly-signed JWT
# + return - the same token with its `sub` claim swapped, signature unchanged
function tamperedAssertion(string token) returns string|error {
    string[] parts = re `\.`.split(token);
    if parts.length() != 3 {
        return error("not a JWT: " + token);
    }
    byte[] payloadBytes = check base64UrlDecode(parts[1]);
    string payloadText = check string:fromBytes(payloadBytes);
    json payloadJson = check payloadText.fromJsonString();
    map<json> payloadMap = <map<json>>payloadJson;
    payloadMap["sub"] = "tampered-subject";
    string newPayloadText = payloadMap.toJsonString();
    string newPayloadSegment = base64UrlEncode(newPayloadText.toBytes());
    return parts[0] + "." + newPayloadSegment + "." + parts[2];
}

function base64UrlDecode(string segment) returns byte[]|error {
    string standard = re `-`.replaceAll(segment, "+");
    standard = re `_`.replaceAll(standard, "/");
    int remainder = standard.length() % 4;
    if remainder == 2 {
        standard = standard + "==";
    } else if remainder == 3 {
        standard = standard + "=";
    }
    return array:fromBase64(standard);
}

function base64UrlEncode(byte[] content) returns string {
    string standard = content.toBase64();
    string urlSafe = re `\+`.replaceAll(standard, "-");
    urlSafe = re `/`.replaceAll(urlSafe, "_");
    urlSafe = re `=+$`.replaceAll(urlSafe, "");
    return urlSafe;
}
