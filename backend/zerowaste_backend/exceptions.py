"""
Custom exception classes for the ZeroWaste application.
"""

from rest_framework import status
from rest_framework.views import exception_handler
from rest_framework.response import Response
import logging

logger = logging.getLogger(__name__)


class ZeroWasteException(Exception):
    """Base exception class for ZeroWaste application."""
    default_message = "An error occurred"
    default_code = "error"
    status_code = status.HTTP_500_INTERNAL_SERVER_ERROR

    def __init__(self, message=None, code=None):
        self.message = message or self.default_message
        self.code = code or self.default_code
        super().__init__(self.message)


class ValidationError(ZeroWasteException):
    """Raised when validation fails."""
    default_message = "Validation failed"
    default_code = "validation_error"
    status_code = status.HTTP_400_BAD_REQUEST


class NotFoundError(ZeroWasteException):
    """Raised when a resource is not found."""
    default_message = "Resource not found"
    default_code = "not_found"
    status_code = status.HTTP_404_NOT_FOUND


class PermissionError(ZeroWasteException):
    """Raised when user doesn't have permission."""
    default_message = "Permission denied"
    default_code = "permission_denied"
    status_code = status.HTTP_403_FORBIDDEN


class AuthenticationError(ZeroWasteException):
    """Raised when authentication fails."""
    default_message = "Authentication failed"
    default_code = "authentication_failed"
    status_code = status.HTTP_401_UNAUTHORIZED


def custom_exception_handler(exc, context):
    """
    Custom exception handler that provides consistent error responses.
    """
    # Call REST framework's default exception handler first
    response = exception_handler(exc, context)

    if response is not None:
        # Log the exception
        logger.error(f"API Exception: {exc}", exc_info=True)
        
        # Customize the response format
        custom_response_data = {
            'error': {
                'message': str(exc),
                'code': getattr(exc, 'code', 'error'),
                'status_code': response.status_code,
                'details': response.data if hasattr(response, 'data') else None
            }
        }
        response.data = custom_response_data

    elif isinstance(exc, ZeroWasteException):
        # Handle custom exceptions
        logger.error(f"ZeroWaste Exception: {exc}", exc_info=True)
        
        response = Response(
            {
                'error': {
                    'message': exc.message,
                    'code': exc.code,
                    'status_code': exc.status_code
                }
            },
            status=exc.status_code
        )

    return response