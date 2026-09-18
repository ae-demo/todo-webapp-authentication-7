// Adapted from thunder-authentication's screens.example.ts pattern for
// todo-webapp's own screens (specs/design/components/todo-webapp/wireframes.dsl).
//
// THIS IS THE ONLY FILE THAT KNOWS ABOUT SCREENS, and all it says about each
// one is which API operation it LOADS. The gate follows: a screen is
// reachable when the caller may call that operation, and what the operation
// needs is in the contract, projected into ./operations.gen.ts.

import { canCall } from "./core";
import { OPERATIONS, isOperationKey, type OperationKey } from "./operations.gen";

export interface ScreenRoute {
  readonly key: string;
  readonly label: string;
  readonly path: string;
  readonly loads: OperationKey | null;
  readonly public?: boolean;
}

/**
 * The wireframe's three screens, in rail order. The one flow, "Manage my
 * todos", has a `role "User"` line, so none of these is public.
 *
 * TodoList reads the caller's own items on open. AddTodo has no load call —
 * its one operation is the create its Save button makes. EditTodo loads the
 * single item it edits.
 */
export const SCREEN_ROUTES: readonly ScreenRoute[] = [
  { key: "todo-list", label: "My Todos", path: "/todos", loads: "GET /me/todo-items" },
  { key: "add-todo", label: "Add Todo", path: "/todos/new", loads: "POST /me/todo-items" },
  {
    key: "edit-todo",
    label: "Edit Todo",
    path: "/todos/:id",
    loads: "GET /me/todo-items/{itemId}",
  },
];

// FAIL LOUDLY, at module load — a committed table that outlived its contract
// must not silently gate on nothing.
for (const screen of SCREEN_ROUTES) {
  if (screen.loads !== null && !isOperationKey(screen.loads)) {
    throw new Error(
      `src/authz/screens.ts: screen "${screen.label}" loads "${screen.loads}", which ` +
        `no contract declares. Re-run \`npm run gen\`, or name the operation the ` +
        `way openapi.yaml spells it.`,
    );
  }
}

export function reachableScreens(
  scopes: ReadonlySet<string>,
  signedIn: boolean,
): readonly ScreenRoute[] {
  return SCREEN_ROUTES.filter((screen) => {
    if (screen.public) return true;
    if (screen.loads === null) return signedIn;
    return canCall(OPERATIONS[screen.loads], scopes, signedIn);
  });
}

export function hasScopedReach(scopes: ReadonlySet<string>, signedIn: boolean): boolean {
  return reachableScreens(scopes, signedIn).some(
    (screen) => !screen.public && screen.loads !== null,
  );
}
