import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

interface ErrorResponse {
  statusCode: number;
  timestamp: string;
  path: string;
  message: string;
  error?: string;
  errors?: any;
  details?: any;
  retryable?: boolean;
}

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Internal server error';
    let error: string | undefined;
    let errors: any = undefined;
    let details: any;
    let retryable = false;

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();

      if (typeof exceptionResponse === 'object') {
        message =
          (exceptionResponse as any).message || exception.message;
        errors = (exceptionResponse as any).errors;
        error = (exceptionResponse as any).error;
        details = (exceptionResponse as any).details;
      } else {
        message = exceptionResponse as string;
      }
    } else if (exception instanceof Error) {
      message = exception.message;
      error = exception.name;

      // Handle specific error types
      if (exception.name === 'QueryFailedError') {
        status = HttpStatus.BAD_REQUEST;
        message = 'Database query failed';
      } else if (exception.name === 'EntityNotFoundError') {
        status = HttpStatus.NOT_FOUND;
        message = 'Resource not found';
      } else if (exception.name === 'ValidationError') {
        status = HttpStatus.BAD_REQUEST;
        message = 'Validation failed';
      } else if (exception.name === 'TimeoutError') {
        status = HttpStatus.REQUEST_TIMEOUT;
        message = 'Request timeout';
        retryable = true;
      } else if (exception.name === 'NetworkError') {
        status = HttpStatus.SERVICE_UNAVAILABLE;
        message = 'Network error occurred';
        retryable = true;
      }
    }

    // Determine if error is retryable
    if (status >= 500 || status === 408 || status === 429) {
      retryable = true;
    }

    // Log error with comprehensive context
    this.logger.error({
      message: `HTTP ${status} Error: ${message}`,
      path: request.url,
      method: request.method,
      statusCode: status,
      error: error,
      userId: (request as any).user?.id,
      userAgent: request.headers['user-agent'],
      ip: request.ip,
      timestamp: new Date().toISOString(),
      stack: exception instanceof Error ? exception.stack : undefined,
      body: request.body,
      query: request.query,
    });

    // Build response
    const errorResponse: ErrorResponse = {
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: request.url,
      message: this.getUserFriendlyMessage(status, message),
      retryable,
    };

    // Include error details
    if (errors) {
      errorResponse.errors = errors;
    }

    // Include error name and details in development
    if (process.env.NODE_ENV === 'development') {
      if (error) errorResponse.error = error;
      if (details) errorResponse.details = details;
    }

    response.status(status).json(errorResponse);
  }

  private getUserFriendlyMessage(status: number, originalMessage: string): string {
    // Provide user-friendly messages for common errors
    const friendlyMessages: Record<number, string> = {
      400: 'Invalid request. Please check your input and try again.',
      401: 'Authentication required. Please log in.',
      403: 'You do not have permission to access this resource.',
      404: 'The requested resource was not found.',
      408: 'Request timeout. Please try again.',
      429: 'Too many requests. Please try again later.',
      500: 'An unexpected error occurred. Please try again.',
      502: 'Service temporarily unavailable. Please try again.',
      503: 'Service temporarily unavailable. Please try again later.',
      504: 'Gateway timeout. Please try again.',
    };

    // Return friendly message if available, otherwise return original
    return friendlyMessages[status] || originalMessage;
  }
}
