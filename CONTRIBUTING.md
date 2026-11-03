# Contributing

Thanks for helping improve Baches.

## Before you start

```bash
cp .env.example .env
make db
cd backend
uv sync
uv run python manage.py migrate
```

## Code style

- Keep functions small and names explicit. Prefer a clear function over an abstraction.
- Code, docstrings and commit messages are in English. User-facing messages are in Spanish.
- Add tests for behavior changes. Spatial behavior needs a test that proves the distance rule.
- Run the checks before opening a pull request:

```bash
make check
make test
```

## Commits

Use conventional commits:

- `feat: add pothole detail endpoint`
- `fix: reject reports outside the city`
- `test: cover deduplication radius`
- `docs: document Google sign-in setup`

## Pull requests

Describe what changed, why, and how you verified it. Include the commands you ran.
Keep pull requests focused on one concern.
