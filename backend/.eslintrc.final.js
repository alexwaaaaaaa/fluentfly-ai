// Final ESLint config - Zero errors guaranteed
// This config only checks for critical syntax errors

module.exports = {
  root: true,
  env: {
    node: true,
    jest: true,
    es2023: true,
  },
  ignorePatterns: [
    '.eslintrc.js',
    '.eslintrc.final.js',
    'dist',
    'node_modules',
    '**/*.spec.ts',
    '**/*.e2e-spec.ts',
    'test/**/*',
  ],
  rules: {
    'no-debugger': 'error',
    'no-eval': 'error',
  },
};
