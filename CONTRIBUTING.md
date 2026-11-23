# Contributing

Issues and pull requests are welcome. Before you open a pull request:

- Run `sh tests/run.sh` and `claude plugin validate . --strict`.
- Keep the helpers POSIX sh and awk, so they run in Git Bash on Windows: no Python, Node or tools found on only one platform.
- Follow the note format and rules in [reference/conventions.md](reference/conventions.md). Tests and examples use only the made-up projects in `examples/`.
