import time
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Task
from .serializers import TaskSerializer, ReorderSerializer

SIMULATED_DELAY_SECONDS = 2


class TaskViewSet(viewsets.ModelViewSet):
    """
    Full CRUD for Tasks plus a /reorder action.

    GET    /api/tasks/           — list (supports ?search= and ?status=)
    POST   /api/tasks/           — create  (2 s simulated delay)
    GET    /api/tasks/{id}/      — retrieve
    PATCH  /api/tasks/{id}/      — partial update (2 s simulated delay)
    PUT    /api/tasks/{id}/      — full update    (2 s simulated delay)
    DELETE /api/tasks/{id}/      — delete
    POST   /api/tasks/reorder/   — persist drag-and-drop sort order
    """

    serializer_class = TaskSerializer
    http_method_names = ['get', 'post', 'patch', 'put', 'delete', 'head', 'options']

    def get_queryset(self):
        qs = Task.objects.select_related('blocked_by').all()

        search = self.request.query_params.get('search', '').strip()
        if search:
            qs = qs.filter(title__icontains=search)

        status_filter = self.request.query_params.get('status', '').strip()
        if status_filter:
            qs = qs.filter(status=status_filter)

        return qs

    # ── Inject simulated delay on writes ──────────────────────────────────

    def create(self, request, *args, **kwargs):
        time.sleep(SIMULATED_DELAY_SECONDS)
        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        time.sleep(SIMULATED_DELAY_SECONDS)
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        kwargs['partial'] = True
        return self.update(request, *args, **kwargs)

    # ── Reorder action ────────────────────────────────────────────────────

    @action(detail=False, methods=['post'], url_path='reorder')
    def reorder(self, request):
        serializer = ReorderSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        ordered_ids = serializer.validated_data['ordered_ids']
        tasks_map   = {str(t.pk): t for t in Task.objects.filter(pk__in=ordered_ids)}

        bulk_update = []
        for idx, task_id in enumerate(ordered_ids):
            task = tasks_map.get(str(task_id))
            if task:
                task.sort_order = idx
                bulk_update.append(task)

        Task.objects.bulk_update(bulk_update, ['sort_order'])
        return Response(status=status.HTTP_204_NO_CONTENT)
