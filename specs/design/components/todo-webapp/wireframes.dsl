screen TodoList "The user's todo items, done and outstanding"
  navbar "Todo"
  heading "My Todos"
  row
    text "Track what you need to do"
    right
    button "Add Todo" primary -> AddTodo
  table "Title | Due Date | Status | " -> EditTodo
    row "Buy groceries | 2026-09-20 | Open | "
    row "Finish report | 2026-09-22 | Open | "
    row "Book flights | — | Done | "

screen AddTodo "Add a new todo item"
  navbar "Todo"
  heading "Add Todo"
  input "Title"
  input "Due date (optional)"
  row
    right
    button "Cancel" -> TodoList
    button "Save" primary -> TodoList

screen EditTodo "Edit or complete a todo item"
  navbar "Todo"
  heading "Edit Todo"
  input "Title"
  input "Due date (optional)"
  checkbox "Done"
  row
    right
    button "Delete" danger -> TodoList
    button "Cancel" -> TodoList
    button "Save" primary -> TodoList

flow "Manage my todos"
  role "User"
  description "A signed-in user adds, completes, edits and removes their own todo items"
  TodoList
  AddTodo
  EditTodo
