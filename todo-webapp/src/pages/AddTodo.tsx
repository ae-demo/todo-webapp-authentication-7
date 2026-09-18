import { useState, type FormEvent, type JSX } from "react";
import { useNavigate } from "react-router-dom";
import { Alert, Button, Form, PageContent, PageTitle, Stack, TextField } from "@wso2/oxygen-ui";
import { todoApi } from "../api";

/** specs/design/components/todo-webapp/wireframes.dsl — screen AddTodo */
export function AddTodoPage(): JSX.Element {
  const navigate = useNavigate();
  const [title, setTitle] = useState("");
  const [dueDate, setDueDate] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const titleError = title.trim().length === 0;

  async function handleSave(event: FormEvent): Promise<void> {
    event.preventDefault();
    if (titleError) return;
    setSaving(true);
    setError(null);
    const { error: apiError } = await todoApi.POST("/me/todo-items", {
      body: { title: title.trim(), dueDate: dueDate || null },
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
        <PageTitle.Header>Add Todo</PageTitle.Header>
      </PageTitle>

      {error && <Alert severity="error">{error}</Alert>}

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
            <Stack direction="row" justifyContent="flex-end" spacing={2}>
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
    </PageContent>
  );
}
