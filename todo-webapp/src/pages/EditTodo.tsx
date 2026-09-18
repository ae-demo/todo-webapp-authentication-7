import { useEffect, useState, type FormEvent, type JSX } from "react";
import { useNavigate, useParams } from "react-router-dom";
import {
  Alert,
  Button,
  Checkbox,
  CircularProgress,
  Form,
  FormControlLabel,
  PageContent,
  PageTitle,
  Stack,
  TextField,
} from "@wso2/oxygen-ui";
import { todoApi } from "../api";

/** specs/design/components/todo-webapp/wireframes.dsl — screen EditTodo */
export function EditTodoPage(): JSX.Element {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [loading, setLoading] = useState(true);
  const [title, setTitle] = useState("");
  const [dueDate, setDueDate] = useState("");
  const [done, setDone] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;
    let live = true;
    setLoading(true);
    setError(null);
    todoApi
      .GET("/me/todo-items/{itemId}", { params: { path: { itemId: id } } })
      .then(({ data, error: apiError }) => {
        if (!live) return;
        if (apiError) {
          setError(apiError.message);
          return;
        }
        if (data) {
          setTitle(data.title);
          setDueDate(data.dueDate ?? "");
          setDone(data.done);
        }
      })
      .catch((e: unknown) => {
        if (live) setError(e instanceof Error ? e.message : "Could not load this todo.");
      })
      .finally(() => {
        if (live) setLoading(false);
      });
    return () => {
      live = false;
    };
  }, [id]);

  const titleError = title.trim().length === 0;

  async function handleSave(event: FormEvent): Promise<void> {
    event.preventDefault();
    if (!id || titleError) return;
    setSaving(true);
    setError(null);
    const { error: apiError } = await todoApi.PATCH("/me/todo-items/{itemId}", {
      params: { path: { itemId: id } },
      body: { title: title.trim(), dueDate: dueDate || null, done },
    });
    setSaving(false);
    if (apiError) {
      setError(apiError.message);
      return;
    }
    navigate("/todos");
  }

  async function handleDelete(): Promise<void> {
    if (!id) return;
    setSaving(true);
    setError(null);
    const { error: apiError } = await todoApi.DELETE("/me/todo-items/{itemId}", {
      params: { path: { itemId: id } },
    });
    setSaving(false);
    if (apiError) {
      setError(apiError.message);
      return;
    }
    navigate("/todos");
  }

  return (
    <PageContent maxWidth={640}>
      <PageTitle>
        <PageTitle.Header>Edit Todo</PageTitle.Header>
      </PageTitle>

      {error && <Alert severity="error">{error}</Alert>}

      {loading ? (
        <CircularProgress />
      ) : (
        <Form.Section>
          <form onSubmit={(e) => void handleSave(e)}>
            <Form.Stack>
              <TextField
                label="Title"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                error={title.length > 0 && titleError}
                helperText={title.length > 0 && titleError ? "Title is required" : undefined}
                required
                fullWidth
              />
              <TextField
                type="date"
                label="Due date (optional)"
                value={dueDate}
                onChange={(e) => setDueDate(e.target.value)}
                slotProps={{ inputLabel: { shrink: true } }}
                fullWidth
              />
              <FormControlLabel
                control={<Checkbox checked={done} onChange={(e) => setDone(e.target.checked)} />}
                label="Done"
              />
              <Stack direction="row" justifyContent="flex-end" spacing={2}>
                <Button variant="outlined" color="error" onClick={() => void handleDelete()} disabled={saving}>
                  Delete
                </Button>
                <Button variant="outlined" onClick={() => navigate("/todos")}>
                  Cancel
                </Button>
                <Button type="submit" variant="contained" disabled={titleError || saving}>
                  Save
                </Button>
              </Stack>
            </Form.Stack>
          </form>
        </Form.Section>
      )}
    </PageContent>
  );
}
