from .base import *
from decouple import config

# Environment-specific settings
if config('ENVIRONMENT', default='development') == 'production':
    from .production import *
elif config('ENVIRONMENT', default='development') == 'testing':
    from .testing import *
else:
    from .development import *