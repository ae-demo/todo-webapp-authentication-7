import { useEffect, useState, type JSX } from "react";
import { useNavigate } from "react-router-dom";
import {
  Alert,
  Button,
  Chip,
  CircularProgress,
  ListingTable,
  PageContent,
  PageTitle,
} from "@wso2/oxygen-ui";
import { Plus } from "@wso2/oxygen-ui-icons-react";
import { todoApi } from "../api";
import type { components } from "../generated/todo-api";

type TodoItem = components["schemas"]["TodoItem"];

function formatDueDate(dueDate: string | null | undefined): string {
  return dueDate ?? "—";
}

/** specs/design/components/todo-webapp/wireframes.dsl — screen TodoList */
export function TodoListPage(): JSX.Element {
  const navigate = useNavigate();
  const [items, setItems] = useState<TodoItem[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let live = true;
    setItems(null);
    setError(null);
    todoApi
      .GET("/me/todo-items", { params: { query: { limit: 100 } } })
      .then(({ data, error: apiError }) => {
        if (!live) return;
        if (apiError) {
          setError(apiError.message);
          return;
        }
        setItems(data?.data ?? []);
      })
      .catch((e: unknown) => {
        if (live) setError(e instanceof Error ? e.message : "Could not load your todos.");
      });
    return () => {
      live = false;
    };
  }, []);

  return (
    <PageContent>
      <PageTitle>
        <PageTitle.Header>My Todos</PageTitle.Header>
        <PageTitle.SubHeader>Track what you need to do</PageTitle.SubHeader>
        <PageTitle.Actions>
          <Button variant="contained" startIcon={<Plus size={18} />} onClick={() => navigate("/todos/new")}>
            Add Todo
          </Button>
        </PageTitle.Actions>
      </PageTitle>

      {error && <Alert severity="error">{error}</Alert>}

      {!error && items === null && <CircularProgress />}

      {!error && items !== null && (
        <ListingTable.Container disablePaper>
          <ListingTable>
            <ListingTable.Head>
              <ListingTable.Row>
                <ListingTable.Cell>Title</ListingTable.Cell>
                <ListingTable.Cell>Due Date</ListingTable.Cell>
                <ListingTable.Cell>Status</ListingTable.Cell>
              </ListingTable.Row>
            </ListingTable.Head>
            <ListingTable.Body>
              {items.length === 0 ? (
                <ListingTable.Row>
                  <ListingTable.Cell colSpan={3}>
                    <ListingTable.EmptyState
                      title="No todos yet"
                      description="Add your first todo to get started."
                    />
                  </ListingTable.Cell>
                </ListingTable.Row>
              ) : (
                items.map((item) => (
                  <ListingTable.Row
                    key={item.id}
                    clickable
                    hover
                    onClick={() => navigate(`/todos/${item.id}`)}
                  >
                    <ListingTable.Cell>{item.title}</ListingTable.Cell>
                    <ListingTable.Cell>{formatDueDate(item.dueDate)}</ListingTable.Cell>
                    <ListingTable.Cell>
                      <Chip
                        label={item.done ? "Done" : "Open"}
                        color={item.done ? "success" : "default"}
                        size="small"
                      />
                    </ListingTable.Cell>
                  </ListingTable.Row>
                ))
              )}
            </ListingTable.Body>
          </ListingTable>
        </ListingTable.Container>
      )}
    </PageContent>
  );
}
