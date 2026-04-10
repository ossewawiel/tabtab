# `.tt.yaml` Examples

Runnable example projects are in `examples/`:

| Example | Path | What it demonstrates |
|---|---|---|
| hello-world | [`examples/hello-world/project.tt.yaml`](../../examples/hello-world/project.tt.yaml) | Minimal screen with a single button |
| customer-manager | [`examples/customer-manager/project.tt.yaml`](../../examples/customer-manager/project.tt.yaml) | REST data source, signals, computed filters, navigation |
| todo-app | [`examples/todo-app/project.tt.yaml`](../../examples/todo-app/project.tt.yaml) | Local state signals, list rendering, computed counts |

## Common patterns

### Static binding
```yaml
Text:
  value: "Hello, world!"
```

### Reactive signal binding
```yaml
Text:
  value: => greeting    # reactive: re-renders when `greeting` signal changes
```

### Computed signal
```yaml
signals:
  fullName:
    type: Computed<String>
    derive: "${firstName} ${lastName}"
```

### Event handler reference
```yaml
Button:
  text: "Save"
  onClick: handleSave   # → calls handleSave() in handlers/MainHandlers.kt
```

### Data source binding
```yaml
dataSources:
  users:
    type: rest
    baseUrl: "${env:API_BASE}"
    endpoints:
      list:
        method: GET
        path: /users
        returns: List<User>

signals:
  userList:
    type: Resource<List<User>>
    source: users.list
```

See `docs/architecture/yaml-schema.md` for the complete schema reference.
