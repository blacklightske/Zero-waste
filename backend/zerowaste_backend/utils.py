from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
import logging

logger = logging.getLogger(__name__)

def custom_exception_handler(exc, context):
    """
    Custom exception handler for REST framework that improves error reporting
    """
    # Call REST framework's default exception handler first
    response = exception_handler(exc, context)
    
    # Log the error
    logger.error(
        f"Exception in {context['view'].__class__.__name__}: {str(exc)}",
        exc_info=True
    )
    
    # If response is None, there was an unhandled exception
    if response is None:
        return Response(
            {"detail": "A server error occurred.", "type": str(type(exc).__name__)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
    return response