module.exports = {
  parser: '@typescript-eslint/parser',
  parserOptions: {
    sourceType: 'module',
    ecmaVersion: 2023,
  },
  plugins: [],
  extends: [],
  root: true,
  env: {
    node: true,
    jest: true,
    es2023: true,
  },
  ignorePatterns: [
    '.eslintrc.js',
    'dist',
    'node_modules',
    '**/*.spec.ts',
    '**/*.e2e-spec.ts',
    'test/**/*',
  ],
  rules: {
    // Only critical errors
    'no-debugger': 'error',
    'no-eval': 'error',
    'no-console': 'off',
  },
};
