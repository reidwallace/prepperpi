# Contributing to PrepperPi

Thanks for taking the time to contribute!

## Quick Start
1. Fork the repo and clone your fork.
2. Create a branch: `git checkout -b feature/short-title`.
3. Make your changes. Please include docs/README updates when relevant.
4. Run linters/tests: `ruff check .`, `black --check .`, `pytest` (if present).
5. Commit: `git commit -m "feat: short summary"`.
6. Push: `git push origin feature/short-title`.
7. Open a Pull Request to `main` with a clear description and screenshots when applicable.

## Coding Standards
- Python: follow [PEP 8], format with `black`, lint with `ruff`.
- Shell: keep scripts POSIX-compliant and `shellcheck` clean.
- Avoid committing secrets, logs, or large binary data.

## Commit Messages
- Conventional style is preferred: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`.

## Reporting Security Issues
Please see [SECURITY.md](SECURITY.md).
