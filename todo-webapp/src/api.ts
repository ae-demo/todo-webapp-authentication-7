import createClient, { type Middleware } from "openapi-fetch";
import type { paths } from "./generated/todo-api";
import { authorizationHeader, classifyResponse, ForbiddenError } from "./authz/client";

// The 401 rule lives entirely in src/authz/client.ts — this file adds NOTHING
// of its own about authorization. Same-origin `/api`: nginx in this pod
// reverse-proxies to the API gateway, which validates the token and injects
// the caller's identity for todo-api.
const authMiddleware: Middleware = {
  async onRequest({ request }) {
    const header = await authorizationHeader();
    if (header) request.headers.set("Authorization", header);
    return request;
  },
  async onResponse({ response }) {
    if ((await classifyResponse(response.status)) === "forbidden") {
      throw new ForbiddenError(response.status);
    }
    return response;
  },
};

export const todoApi = createClient<paths>({ baseUrl: "/api" });
todoApi.use(authMiddleware);
