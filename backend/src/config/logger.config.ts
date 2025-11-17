import { WinstonModule } from 'nest-winston';
import * as winston from 'winston';

const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.splat(),
  winston.format.json(),
);

const consoleFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.colorize(),
  winston.format.printf(({ timestamp, level, message, context, ...meta }) => {
    let msg = `${timestamp} [${context || 'Application'}] ${level}: ${message}`;
    
    // Add metadata if present
    const metaStr = Object.keys(meta).length > 0 ? JSON.stringify(meta) : '';
    if (metaStr) {
      msg += ` ${metaStr}`;
    }
    
    return msg;
  }),
);

export const createWinstonLogger = () => {
  const transports: winston.transport[] = [
    // Console transport for all environments
    new winston.transports.Console({
      format: consoleFormat,
      level: process.env.LOG_LEVEL || 'info',
    }),
  ];

  // Add file transports in production
  if (process.env.NODE_ENV === 'production') {
    transports.push(
      // Error logs
      new winston.transports.File({
        filename: 'logs/error.log',
        level: 'error',
        format: logFormat,
        maxsize: 5242880, // 5MB
        maxFiles: 5,
      }),
      // Combined logs
      new winston.transports.File({
        filename: 'logs/combined.log',
        format: logFormat,
        maxsize: 5242880, // 5MB
        maxFiles: 5,
      }),
    );
  }

  return WinstonModule.createLogger({
    transports,
    exitOnError: false,
    // Don't log in test environment
    silent: process.env.NODE_ENV === 'test',
  });
};
