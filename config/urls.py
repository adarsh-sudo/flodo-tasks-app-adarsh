from django.urls import path, include
from django.contrib import admin
urlpatterns = [
    path('admin/', admin.site.urls), 
    path('api/', include('tasks.urls')),
    path('health/', lambda request: __import__('django.http', fromlist=['JsonResponse']).JsonResponse({'status': 'ok'})),
]
