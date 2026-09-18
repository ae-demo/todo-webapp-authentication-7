// The keys the platform actually emits for this component: the `user-auth`
// platform-resource dependency's OIDC config. No <NAME>_URL for todo-api — it
// is a component-kind sibling, reached at same-origin /api, never a browser key.
export const mockEnv = {
  USER_AUTH_CLIENT_ID: "mock-client",
  USER_AUTH_ISSUER: "https://mock-idp.test",
  // No USER_AUTH_JWKS_URL: the browser never validates a token — the API
  // gateway does — so src/env.ts does not declare it and mock mode does not
  // carry it. The OIDC scopes are `group` and `ou`, singular, plus this
  // project's own catalog handles.
  USER_AUTH_SCOPES: "openid profile email group ou todo-items:read todo-items:write",
  USER_AUTH_RESOURCE: "https://aep.wso2.com/orgs/mock-org/projects/todo-webapp-authentication-7",
};
