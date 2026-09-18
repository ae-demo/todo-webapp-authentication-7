import type { JSX } from "react";
import { Link as RouterLink, Outlet, useLocation } from "react-router-dom";
import {
  AppShell as OxygenAppShell,
  ColorSchemeToggle,
  Divider,
  Footer,
  Header,
  Sidebar,
  UserMenu,
} from "@wso2/oxygen-ui";
import { ListTodo, LogOut, User as UserIcon } from "@wso2/oxygen-ui-icons-react";
import { APP_NAME } from "../appName";
import { Can, useAuthz } from "../authz/gates";
import { signOut } from "../authz/session";

/**
 * The app chrome, per wireframes.dsl's `navbar "Todo"` on every screen and
 * the oxygen-ui-design-system's canonical AppShell. The DSL draws no
 * `sidebar` line — this one-flow app has a single nav destination, TodoList
 * — so the rail carries that one item, gated the same way any nav item is.
 */
export function AppShell(): JSX.Element {
  const { username } = useAuthz();
  const { pathname } = useLocation();
  const active = pathname.startsWith("/todos") && !pathname.startsWith("/todos/new") ? "todo-list" : "";

  return (
    <OxygenAppShell>
      <OxygenAppShell.Navbar>
        <Header>
          <Header.Toggle />
          <Header.Brand>
            <Header.BrandTitle>{APP_NAME}</Header.BrandTitle>
          </Header.Brand>
          <Header.Spacer />
          <Header.Actions>
            <ColorSchemeToggle />
            <Divider orientation="vertical" flexItem sx={{ mx: 2 }} />
            <UserMenu>
              <UserMenu.Trigger name={username || "Signed in"} />
              <UserMenu.Header name={username || "Signed in"} email="" />
              <UserMenu.Item icon={<UserIcon />} label="Profile" onClick={() => {}} />
              <UserMenu.Divider />
              <UserMenu.Logout icon={<LogOut />} onClick={() => void signOut()} />
            </UserMenu>
          </Header.Actions>
        </Header>
      </OxygenAppShell.Navbar>

      <OxygenAppShell.Sidebar>
        <Sidebar activeItem={active}>
          <Sidebar.Nav>
            <Sidebar.Category>
              <Can op="GET /me/todo-items">
                <Sidebar.Item id="todo-list" link={<RouterLink to="/todos" />}>
                  <Sidebar.ItemIcon>
                    <ListTodo />
                  </Sidebar.ItemIcon>
                  <Sidebar.ItemLabel>My Todos</Sidebar.ItemLabel>
                </Sidebar.Item>
              </Can>
            </Sidebar.Category>
          </Sidebar.Nav>
        </Sidebar>
      </OxygenAppShell.Sidebar>

      <OxygenAppShell.Main>
        <Outlet />
      </OxygenAppShell.Main>

      <OxygenAppShell.Footer>
        <Footer>
          <Footer.Copyright>© {new Date().getFullYear()} WSO2 LLC.</Footer.Copyright>
        </Footer>
      </OxygenAppShell.Footer>
    </OxygenAppShell>
  );
}
