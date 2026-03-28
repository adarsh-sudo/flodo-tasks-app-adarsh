import uuid
from django.db import models


class TaskStatus(models.TextChoices):
    TODO        = 'todo',        'To-Do'
    IN_PROGRESS = 'in_progress', 'In Progress'
    DONE        = 'done',        'Done'


class Task(models.Model):
    id          = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title       = models.CharField(max_length=255)
    description = models.TextField(blank=True, default='')
    due_date    = models.DateTimeField()
    status      = models.CharField(
                    max_length=20,
                    choices=TaskStatus.choices,
                    default=TaskStatus.TODO,
                  )
    blocked_by  = models.ForeignKey(
                    'self',
                    null=True, blank=True,
                    on_delete=models.SET_NULL,
                    related_name='blocking',
                  )
    sort_order  = models.IntegerField(default=0)
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['sort_order', 'due_date']

    def __str__(self):
        return self.title
