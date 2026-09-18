import { http, HttpResponse } from "msw";
import type { components } from "../src/generated/todo-api";

type TodoItem = components["schemas"]["TodoItem"];
type TodoItemInput = components["schemas"]["TodoItemInput"];
type TodoItemUpdate = components["schemas"]["TodoItemUpdate"];

// The caller this mock speaks for. todo-api has ONLY /me/ operations, so there
// is no every-row endpoint to compare against — the "someone else's" row below
// exists purely to prove GET /me/todo-items filters by owner rather than
// returning every row in module scope.
export const mockCaller = { username: "mock-user" };
const SOMEONE_ELSE = "someone-else";

// Module-scope state: a full page load re-runs this module and resets the
// seed (see react-webapp's mock-mode reference) — only in-app navigation
// carries a change forward. Seeded with the wireframe's own rows
// (specs/design/components/todo-webapp/wireframes.dsl, screen TodoList) so the
// walk compares against the same data the wireframe draws.
let todos: (TodoItem & { owner: string })[] = [
  {
    id: "1",
    title: "Buy groceries",
    done: false,
    dueDate: "2026-09-20",
    createdAt: "2026-09-15T09:00:00.000Z",
    updatedAt: "2026-09-15T09:00:00.000Z",
    owner: mockCaller.username,
  },
  {
    id: "2",
    title: "Finish report",
    done: false,
    dueDate: "2026-09-22",
    createdAt: "2026-09-16T09:00:00.000Z",
    updatedAt: "2026-09-16T09:00:00.000Z",
    owner: mockCaller.username,
  },
  {
    id: "3",
    title: "Book flights",
    done: true,
    dueDate: null,
    createdAt: "2026-09-10T09:00:00.000Z",
    updatedAt: "2026-09-17T09:00:00.000Z",
    owner: mockCaller.username,
  },
  {
    id: "4",
    title: "Someone else's todo",
    done: false,
    dueDate: null,
    createdAt: "2026-09-10T09:00:00.000Z",
    updatedAt: "2026-09-10T09:00:00.000Z",
    owner: SOMEONE_ELSE,
  },
];
let nextId = 5;

function toApiShape(todo: TodoItem & { owner: string }): TodoItem {
  const { owner: _owner, ...rest } = todo;
  return rest;
}

function errorBody(code: number, message: string) {
  return { code, message };
}

export const handlers = [
  // The caller's own todos. No `todo-items:read` check here — a caller who
  // does not hold it was refused by mock/authz/gateway.ts and never reached
  // this handler.
  http.get("/api/me/todo-items", ({ request }) => {
    const url = new URL(request.url);
    const limit = Number(url.searchParams.get("limit") ?? "20");
    const offset = Number(url.searchParams.get("offset") ?? "0");
    const mine = todos.filter((t) => t.owner === mockCaller.username);
    const page = mine.slice(offset, offset + limit);
    return HttpResponse.json({
      count: mine.length,
      next: offset + limit < mine.length ? `/me/todo-items?limit=${limit}&offset=${offset + limit}` : null,
      previous: offset > 0 ? `/me/todo-items?limit=${limit}&offset=${Math.max(0, offset - limit)}` : null,
      data: page.map(toApiShape),
    });
  }),

  http.post("/api/me/todo-items", async ({ request }) => {
    const input = (await request.json()) as Partial<TodoItemInput>;
    if (!input?.title || input.title.trim().length === 0) {
      return HttpResponse.json(errorBody(400, "title is required"), { status: 400 });
    }
    const now = new Date().toISOString();
    const created: TodoItem & { owner: string } = {
      id: String(nextId++),
      title: input.title,
      done: false,
      dueDate: input.dueDate ?? null,
      createdAt: now,
      updatedAt: now,
      owner: mockCaller.username,
    };
    todos = [...todos, created];
    return HttpResponse.json(toApiShape(created), { status: 201 });
  }),

  http.get("/api/me/todo-items/:itemId", ({ params }) => {
    const found = todos.find((t) => t.id === params.itemId && t.owner === mockCaller.username);
    if (!found) {
      return HttpResponse.json(errorBody(404, "no such todo item"), { status: 404 });
    }
    return HttpResponse.json(toApiShape(found));
  }),

  http.patch("/api/me/todo-items/:itemId", async ({ params, request }) => {
    const index = todos.findIndex((t) => t.id === params.itemId && t.owner === mockCaller.username);
    if (index === -1) {
      return HttpResponse.json(errorBody(404, "no such todo item"), { status: 404 });
    }
    const update = (await request.json()) as TodoItemUpdate;
    if (update.title !== undefined && update.title.trim().length === 0) {
      return HttpResponse.json(errorBody(400, "title cannot be empty"), { status: 400 });
    }
    const current = todos[index];
    const updated: TodoItem & { owner: string } = {
      ...current,
      ...(update.title !== undefined ? { title: update.title } : {}),
      ...(update.dueDate !== undefined ? { dueDate: update.dueDate } : {}),
      ...(update.done !== undefined ? { done: update.done } : {}),
      updatedAt: new Date().toISOString(),
    };
    todos = [...todos.slice(0, index), updated, ...todos.slice(index + 1)];
    return HttpResponse.json(toApiShape(updated));
  }),

  http.delete("/api/me/todo-items/:itemId", ({ params }) => {
    const before = todos.length;
    todos = todos.filter((t) => !(t.id === params.itemId && t.owner === mockCaller.username));
    if (todos.length === before) {
      return HttpResponse.json(errorBody(404, "no such todo item"), { status: 404 });
    }
    return new HttpResponse(null, { status: 204 });
  }),
];
