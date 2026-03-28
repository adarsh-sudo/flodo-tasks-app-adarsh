# Flodo Tasks

A full-stack task management app built for the Flodo AI take-home assignment.

**Track A — Full-Stack Builder**
**Stretch Goal — Debounced Autocomplete Search with match highlighting**

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Backend Setup (Django)](#backend-setup)
3. [Frontend Setup (Flutter)](#frontend-setup)
4. [API Reference](#api-reference)
5. [Features Checklist](#features-checklist)
6. [AI Usage Report](#ai-usage-report)

---

## Project Structure

```
flodo_tasks/
├── config/                  ← Django project settings and URL root
│   ├── settings.py
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
├── tasks/                   ← The Django app — all backend logic lives here
│   ├── models.py            ← Task database model
│   ├── serializers.py       ← JSON validation and shaping
│   ├── views.py             ← API endpoints (ViewSet + reorder action)
│   ├── urls.py              ← Route registration
│   └── migrations/          ← Auto-generated DB migration files
├── manage.py                ← Django CLI entrypoint
├── requirements.txt         ← Python dependencies
│
└── flutter_app/
    ├── pubspec.yaml         ← Flutter dependencies
    └── lib/
        ├── main.dart            ← App entry point
        ├── models/
        │   ├── task.dart        ← Task data class + TaskStatus enum
        │   └── draft.dart       ← Unsaved form state model
        ├── providers/
        │   ├── task_provider.dart   ← Task list state + all API calls
        │   └── draft_provider.dart  ← Form draft state + persistence
        ├── screens/
        │   ├── home_screen.dart         ← Main task list
        │   ├── task_form_screen.dart    ← Create / Edit form
        │   └── task_detail_screen.dart  ← Read-only detail view
        ├── widgets/
        │   ├── task_card.dart          ← List card with blocked state + swipe-delete
        │   ├── filter_bar.dart         ← Debounced search + status filter chips
        │   ├── save_button.dart        ← Spinner button, prevents double-tap
        │   ├── status_badge.dart       ← Coloured To-Do / In Progress / Done pill
        │   └── highlighted_text.dart   ← Bolds matched search letters in results
        ├── theme/
        │   └── app_theme.dart   ← All colours, typography, component styles
        └── utils/
            ├── api_service.dart    ← All HTTP calls to Django
            └── draft_storage.dart  ← SharedPreferences read/write for drafts
```

---

## Backend Setup

### Prerequisites

- Python 3.11 or higher
- pip

### Step 1 — Navigate to the project root

```bash
cd flodo-tasks-app-adarsh

```

### Step 2 — Create and activate a virtual environment

```bash
# macOS / Linux
python3 -m venv venv
source venv/bin/activate

# Windows (Command Prompt)
python -m venv venv
venv\Scripts\activate.bat

# Windows (PowerShell)
python -m venv venv
venv\Scripts\Activate.ps1
```

You should see `(venv)` at the start of your terminal prompt.

### Step 3 — Install Python dependencies

```bash
pip install -r requirements.txt
```

This installs:
- `django` — the web framework
- `djangorestframework` — REST API toolkit
- `django-cors-headers` — allows the Flutter app to talk to this server

### Step 4 — Apply database migrations

```bash
python manage.py migrate
```

This creates the `db.sqlite3` file and builds the `tasks` table from `tasks/models.py`.

### Step 5 — Start the server

```bash
python manage.py runserver 0.0.0.0:8000
```

The `0.0.0.0` part makes the server reachable from the Android emulator and physical devices on the same network, not just your browser.

You should see:

```
Starting development server at http://0.0.0.0:8000/
```

### Step 6 — Verify it's working

Open your browser and go to:

```
http://localhost:8000/api/tasks/
```

You should see the DRF browsable API with an empty task list `[]`.

---

## Frontend Setup

### Prerequisites

- Flutter SDK 3.22 or higher — install from https://docs.flutter.dev/get-started/install
- Android Studio with an Android emulator set up, OR a physical Android/iOS device
- Run `flutter doctor` and resolve any issues it reports before continuing

### Step 1 — Navigate to the Flutter app

```bash
cd flodo_tasks/flutter_app
```

### Step 2 — Configure the backend URL

Open `lib/utils/api_service.dart` in any text editor and find this line near the top:

```dart
static const _base = 'http://10.0.2.2:8000/api';
```

Change it based on where you're running the Flutter app:

| Scenario | URL to use |
|---|---|
| Android emulator (default) | `http://10.0.2.2:8000/api` |
| iOS simulator | `http://127.0.0.1:8000/api` |
| Physical Android/iOS on same Wi-Fi | `http://YOUR_COMPUTER_LAN_IP:8000/api` |

To find your LAN IP:
- **macOS**: `ipconfig getifaddr en0` in terminal
- **Windows**: `ipconfig` in Command Prompt, look for IPv4 Address
- **Linux**: `hostname -I`

### Step 3 — Install Flutter dependencies

```bash
flutter pub get
```

### Step 4 — Start an emulator or connect a device

```bash
# List available devices
flutter devices

# If no emulator is running, start one from Android Studio:
# Tools → Device Manager → Play button next to your emulator
```

### Step 5 — Run the app

```bash
flutter run
```

Flutter will build and install the app on your device. The first build takes 1–2 minutes. Subsequent runs are much faster.

> **Important:** Make sure the Django server from the backend steps is still running before you launch the app, otherwise you will see a connection error on the home screen.

---

## API Reference

All endpoints are under `/api/tasks/`.

| Method | URL | Description |
|--------|-----|-------------|
| `GET` | `/api/tasks/` | List all tasks. Optional: `?search=text` and `?status=todo\|in_progress\|done` |
| `POST` | `/api/tasks/` | Create a new task. Has a **2-second simulated delay**. |
| `GET` | `/api/tasks/{id}/` | Retrieve a single task by UUID |
| `PATCH` | `/api/tasks/{id}/` | Partially update a task. Has a **2-second simulated delay**. |
| `DELETE` | `/api/tasks/{id}/` | Delete a task. Also clears `blocked_by` on any tasks that depended on it. |
| `POST` | `/api/tasks/reorder/` | Persist drag-and-drop order. Body: `{ "ordered_ids": ["uuid1", "uuid2", ...] }` |
| `GET` | `/health/` | Health check — returns `{"status": "ok"}` |

### Example POST body for creating a task

```json
{
  "title": "Write unit tests",
  "description": "Cover the serializer and view layers",
  "due_date": "2025-09-01T00:00:00Z",
  "status": "todo",
  "blocked_by_id": null
}
```

---

## Features Checklist

### Core requirements

| Feature | Where it lives |
|---|---|
| Task fields: title, description, due date, status, blocked-by | `tasks/models.py` + `task_form_screen.dart` |
| Blocked task looks visually distinct (greyed out, lock icon) | `task_card.dart` — checks `provider.isBlocked(task)` |
| Blocked task unblocks automatically when blocker is marked Done | `task_provider.dart` — `isBlocked()` re-evaluates live |
| Create, Read, Update, Delete | `tasks/views.py` `TaskViewSet` + all three Flutter screens |
| 2-second delay on Create and Update | `time.sleep(2)` in `views.py` `create()` and `update()` |
| UI does not freeze during delay | Flutter's `async/await` keeps the UI thread free |
| Loading state shown during save | `SaveButton` shows `CircularProgressIndicator` while `isSaving == true` |
| Save button cannot be tapped twice | `SaveButton` sets `onTap: null` while saving |
| Draft persists across minimize / swipe-back | `DraftProvider` + `DraftStorage` writes to `SharedPreferences` on every keystroke |
| Search tasks by title | `FilterBar` debounced text field → `TaskProvider.setSearch()` |
| Filter by status | Chip row in `FilterBar` → `TaskProvider.setStatusFilter()` |

### Stretch goal — Debounced Autocomplete Search

| Feature | Where it lives |
|---|---|
| 300 ms debounce on search input | `filter_bar.dart` — `Timer(Duration(milliseconds: 300), ...)` cancelled and restarted on every keystroke |
| Matching letters highlighted in results | `highlighted_text.dart` — splits the title into `TextSpan`s, styles the matching chunk with accent colour and background tint |

### Bonus

| Feature | Where it lives |
|---|---|
| Drag-and-drop reorder with persistence | `ReorderableListView` in `home_screen.dart` → `POST /api/tasks/reorder/` → Django `bulk_update` |

---

## Technical Decision I'm Proud Of

### `on_delete=SET_NULL` on the self-referential blocked_by foreign key

In `tasks/models.py`, the `blocked_by` field is a foreign key that points to another row in the **same** table:

```python
blocked_by = models.ForeignKey(
    'self',
    null=True, blank=True,
    on_delete=models.SET_NULL,   # ← this choice matters
    related_name='blocking',
)
```


## AI Usage Report

AI tools used: Claude (Anthropic)

### Prompts that produced the most useful code

**1. The self-referential model + serializer:**
> "Write a Django DRF ModelViewSet for a Task model with a self-referential blocked_by FK, a reorder action that accepts an ordered list of UUIDs and uses bulk_update, and a serializer that exposes blocked_by_id as a writable field and blocked_by_title as a read-only computed field."

This gave a working first draft of `models.py`, `serializers.py`, and `views.py` together, which is harder to get right when written separately because the serializer field names have to match the model's `source` attributes exactly.

**2. Flutter debounced search with highlight:**
> "Write a Flutter StatefulWidget search field with a 300ms Timer debounce that calls a Provider method, plus a separate HighlightedText widget that uses RichText and TextSpan to bold the matched substring."

This saved significant time because `RichText` + `TextSpan` is one of the more verbose Flutter APIs and the substring-splitting loop is easy to get off-by-one wrong.

**3. ReorderableListView with conditional fallback:**
> "Write a Flutter ReorderableListView.builder that calls provider.reorder(oldIndex, newIndex), but falls back to a plain ListView.builder when search or status filters are active, because reorder doesn't make sense on a filtered subset."

This surfaced an edge case I hadn't considered — you can't meaningfully reorder a filtered list because the indices don't correspond to the full list positions.

### Instance where AI produced wrong code

The AI initially generated `on_delete=models.CASCADE` for the `blocked_by` foreign key. With `CASCADE`, deleting a blocking task would silently cascade-delete every task that depended on it. This is the wrong behaviour — deleting a blocker should free the blocked task, not delete it.

**Fix:** Changed to `on_delete=models.SET_NULL`. Also had to add `null=True, blank=True` to the field definition, and update the serializer to use `allow_null=True, required=False` on the `blocked_by_id` field to match.
