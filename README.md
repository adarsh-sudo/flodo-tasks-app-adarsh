# Flodo Tasks — Take-Home Assignment

A full-stack task management app built with **Flutter + Django REST Framework**.

---

## Track & Stretch Goal

- **Track A — Full-Stack Builder**
  - Backend: Django 5 + Django REST Framework + SQLite
  - Frontend: Flutter (Dart)
- **Stretch Goal — Debounced Autocomplete Search**
  - 300 ms debounce on the search field
  - Matching substrings are highlighted directly inside task title text on the list

---

## Project Structure

```
flodo_tasks/
├── backend/               ← Django project root
│   ├── config/            ← settings, urls, wsgi/asgi
│   ├── tasks/             ← the tasks Django app
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── views.py       ← TaskViewSet + reorder action
│   │   └── urls.py
│   ├── manage.py
│   └── requirements.txt
│
└── flutter_app/           ← Flutter project root
    ├── lib/
    │   ├── main.dart
    │   ├── models/        ← Task, Draft
    │   ├── providers/     ← TaskProvider, DraftProvider
    │   ├── screens/       ← HomeScreen, TaskFormScreen, TaskDetailScreen
    │   ├── widgets/       ← TaskCard, FilterBar, SaveButton, StatusBadge, HighlightedText
    │   ├── theme/         ← AppTheme, AppColors
    │   └── utils/         ← ApiService, DraftStorage
    └── pubspec.yaml
```

---

## Setup Instructions

### 1. Backend

**Requirements:** Python 3.11+

```bash
cd flodo_tasks/backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

The API is now live at `http://localhost:8000/api/tasks/`.

Browse auto-generated docs (DRF browsable API) at `http://localhost:8000/api/tasks/`.

---

### 2. Flutter App

**Requirements:** Flutter 3.22+ / Dart 3.3+

#### Configure the backend URL

Open `flutter_app/lib/utils/api_service.dart` and set `_base` to your machine's address:

| Scenario | URL |
|---|---|
| Android emulator (default) | `http://10.0.2.2:8000/api` |
| iOS simulator | `http://127.0.0.1:8000/api` |
| Physical device on same Wi-Fi | `http://<your-LAN-IP>:8000/api` |

#### Run

```bash
cd flodo_tasks/flutter_app
flutter pub get
flutter run
```

---

## API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/tasks/` | List all tasks. Supports `?search=` and `?status=` |
| POST | `/api/tasks/` | Create task *(2 s simulated delay)* |
| GET | `/api/tasks/{id}/` | Retrieve single task |
| PATCH | `/api/tasks/{id}/` | Partial update *(2 s simulated delay)* |
| DELETE | `/api/tasks/{id}/` | Delete task |
| POST | `/api/tasks/reorder/` | Persist drag-and-drop order `{ "ordered_ids": [...] }` |
| GET | `/health/` | Health check |

---

## Core Features Implemented

| Requirement | Implementation |
|---|---|
| Task fields: title, description, due date, status, blocked-by | `Task` model / `TaskSerializer` |
| Blocked task visual distinction | `TaskCard` renders greyed-out with lock icon when blocker ≠ Done |
| CRUD | Full create / read / update / delete via DRF `ModelViewSet` |
| 2-second simulated delay (non-freezing UI) | `time.sleep(2)` in `create` / `update` views; Flutter shows spinner & disables Save |
| Prevent double-tap on Save | `SaveButton` sets `onTap: null` while `isSaving == true` |
| Drafts persist across app minimize / swipe-back | `DraftProvider` + `SharedPreferences` saves on every keystroke |
| Search by title | `FilterBar` text field → `TaskProvider.setSearch()` → client-side filter |
| Filter by status | Chip row → `TaskProvider.setStatusFilter()` |
| Drag-and-drop reorder | `ReorderableListView` → `POST /api/tasks/reorder/` persists to DB |
| Debounced search (stretch goal) | 300 ms `Timer` debounce in `FilterBar._onSearchChanged` |
| Match highlight (stretch goal) | `HighlightedText` widget wraps matching substring in accent colour |

---

## Technical Decisions

### Django over FastAPI for the backend

DRF's `ModelViewSet` gave us free browsable API, robust validation via serializers,
and `bulk_update` for the reorder endpoint — all with very little boilerplate.
The self-referential FK (`blocked_by = ForeignKey('self')`) with `on_delete=SET_NULL`
cleanly handles cascading deletes without any extra application logic.

### Client-side filtering vs server-side

Search and status filter are applied client-side on the already-loaded task list.
This keeps the UI snappy (no network round-trips while typing) and is appropriate
for the typical task-list scale. Server-side query params (`?search=&?status=`) are
also supported and used by the backend for completeness and future scalability.

### UUID primary keys generated on the client

Generating UUIDs in Flutter before the POST means the app can optimistically
reference the new task ID immediately, and avoids a second GET after creation.

### `ReorderableListView` + server persistence

Flutter's built-in `ReorderableListView` handles all the drag-and-drop animation.
On drop we immediately reorder the local list (instant visual feedback), then fire
a `POST /api/tasks/reorder/` with the new ordered ID list — a single `bulk_update`
in Django updates all `sort_order` values atomically.

---

## AI Usage Report

### Prompts that were most helpful

- *"Write a Django DRF ModelViewSet for a Task model with a self-referential blocked_by FK, including a custom reorder action that accepts an ordered list of UUIDs and uses bulk_update."*
- *"Write a Flutter ReorderableListView that calls a provider reorder method, but falls back to a plain ListView when search or status filters are active."*
- *"Implement a 300ms debounced TextField in Flutter using dart:async Timer, with a clear (×) suffix icon that appears while the field has text."*

### Instance where AI gave wrong code

The AI initially generated `ForeignKey('self', on_delete=models.CASCADE)` for `blocked_by`. Cascading deletes on a self-referential FK would delete all tasks blocked by a deleted task, which is wrong — the correct behaviour is to unblock them. Fixed by switching to `on_delete=models.SET_NULL` and adding `null=True, blank=True`.
