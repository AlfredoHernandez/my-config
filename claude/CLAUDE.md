# Git Commits
- Never add "Co-Authored-By" trailers to commit messages
- After completing changes, generate the commit message using the `git-commit-message` agent

# Code Quality

- Always act as a Senior Software Engineer and a Architect
- Follow SOLID principles, clean architecture, and established design patterns
- Prefer composition over inheritance
- Keep functions small and focused on a single responsibility
- Threading handling is very important in tests

# Development Workflow

- Run related tests after refactors to verify nothing is broken
- When fixing a bug, write a failing test first, then fix it
- Prefer small, focused changes over large sweeping modifications

# Testing

Shared across all language-specific testing agents. Language syntax lives in `swift-testing` / `kotlin-testing`.

- **Name variables by role, not type.** The class can be `RouterSpy`; the variable is still `router`. Wrong: `let spy = RouterSpy()`. Correct: `let router = RouterSpy()`.
- **Use a `makeSUT()` helper** that returns `(sut, collaborator)` so tests can destructure: `let (sut, router) = makeSUT()`.
- **Test doubles (Fowler's taxonomy)**: Dummy (unused param), Stub (control input), Fake (simplified impl), Spy (record interactions), Spy+Stub (most common). **Avoid library Mocks** (Mockito, MockK, etc.) — they couple tests to implementation details and break on refactors.
- **Search before creating.** Grep for existing `*Spy`, `*Stub`, `*Fake`, `makeSUT`, `anyURL`, `anyError` in test helpers / shared modules before adding a new one. If a private double is needed elsewhere, extract it to a shared location instead of duplicating.
- **File structure inside a test suite:** test cases → helpers (`makeSUT`, `anyURL`, fixtures) → private test doubles, in that order.
- **Test names describe observable behavior**, not implementation. Present tense, third person, no "should", no `test_` prefix unless the framework requires it. Bad: `mapWorks`, `happyPath`, `insertCorrectly`. Good: `Load delivers cached images on non-expired cache`, `Init does not message the store`, `Map throws error on non-200 HTTP response`. The concrete format (backticks vs `test_snake_case`) lives in each testing agent.

# Swift 

- For swift documentation use the `swift-docs` agent when needed
