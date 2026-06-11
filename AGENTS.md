# AI Agent Guidelines for Granite

Welcome, AI Agents! When contributing to the Granite project, please strictly adhere to the following guidelines to ensure your code integrates seamlessly and maintains the high standards of the Amber framework.

## 1. Language Constraints
- **This is Crystal, not Ruby.** While Crystal's syntax is inspired by Ruby, it is a distinctly different, statically typed language. Do not use Ruby-isms, `method_missing` magic, or dynamic meta-programming hacks.
- Crystal is statically typed. Respect the type system and define types explicitly where it improves readability and compilation safety.

## 2. Safety and Types
- **Avoid unsafe assertions:** Never use `.not_nil!` assertions unless absolutely mathematically certain, and even then, consider alternatives. Use proper type narrowing instead (e.g., `if let`, `.try`, `.as?`, or assigning to a variable within an `if` condition like `if var = nullable_var`).

## 3. Serialization
- **Use standard serialization:** Do not use the deprecated `yaml_mapping` or `json_mapping` macros. Always use `YAML::Serializable` and `JSON::Serializable` to define serialized models and classes.

## 4. Modern Features
- **Crystal 1.20+:** Prefer modern Crystal 1.20 features. In particular, leverage features like `M:N` scheduling safe concurrency patterns when writing parallel or concurrent code.

## 5. Development Workflow
- **Formatting and Linting:** Always run `ameba` to verify linting and formatting before committing any changes. Your code must adhere to the project's formatting standards.
- **Testing:** Always run `crystal spec` to ensure all tests pass. If you are adding a new feature or fixing a bug, include corresponding specs and guarantee no regressions are introduced.

Thank you for your contributions!
