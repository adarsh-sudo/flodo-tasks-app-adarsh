from rest_framework import serializers
from .models import Task


class TaskSerializer(serializers.ModelSerializer):
    blocked_by_id = serializers.PrimaryKeyRelatedField(
        source='blocked_by',
        queryset=Task.objects.all(),
        allow_null=True,
        required=False,
        pk_field=serializers.UUIDField(format='hex_verbose'),
    )
    blocked_by_title = serializers.SerializerMethodField()

    class Meta:
        model  = Task
        fields = [
            'id', 'title', 'description', 'due_date',
            'status', 'blocked_by_id', 'blocked_by_title',
            'sort_order', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'blocked_by_title']

    def get_blocked_by_title(self, obj):
        return obj.blocked_by.title if obj.blocked_by else None

    def validate(self, data):
        instance = self.instance
        blocker  = data.get('blocked_by', getattr(instance, 'blocked_by', None))
        if blocker and instance and str(blocker.pk) == str(instance.pk):
            raise serializers.ValidationError("A task cannot block itself.")
        return data


class ReorderSerializer(serializers.Serializer):
    ordered_ids = serializers.ListField(
        child=serializers.UUIDField(format='hex_verbose')
    )
