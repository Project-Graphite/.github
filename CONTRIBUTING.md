# Contributing

## Adding a project

**1. Create the repository.** Start from
[project-template](https://github.com/project-graphite/project-template) — use *Use this template*,
not a fork. It carries the CI wiring, the compose setup and the layout conventions.

Name it in lowercase with hyphens. The name becomes the subdomain, so `game-forge` is served at
`game-forge.project-graphite.com`.

**2. Build it.** Keep the whole project in one repository, with each part in its own top-level
folder. A folder containing a `Dockerfile` is a deployable service and is built automatically.

Keep code in a named folder even when there is only one — image names are derived from it.

**3. Give each service its checks.**

| Folder contains | CI runs |
| :--- | :--- |
| `package.json` | `npm ci`, then the `lint`, `test` and `build` scripts if present |
| `Makefile` | `make install`, `make lint`, `make test` |
| neither | nothing beyond the image build |

**4. Write the README.** What it is, a screenshot or short GIF, the live link, the stack, and how
to run it locally. This is what people actually read, and it is what decides whether the project
gets listed.

**5. Register it.** Open a pull request on the `platform` repository adding
`projects/<slug>.yml`. The README there documents every field. You will be asked about the
summary, the resources requested and any secrets needed — the host is shared, so these are
reviewed rather than rubber-stamped.

Until that entry is merged, CI builds and checks run normally and only the deploy step is blocked,
with a message saying so.

## Conventions

**Pull request titles** follow `type(scope): summary`, using one of `feat fix chore refactor docs
test ci perf revert style build`. Merges are squashed, so the title becomes the commit message on
`main`.

**Pull requests get a size label** based on changed lines, excluding lockfiles. Large ones are not
blocked, but they are slower to review and more likely to sit.

**Secrets never go in a repository.** The registry entry names the environment variables a service
needs; the values live on the host. Every push is scanned, and a committed secret fails the build.

## Reviews

Your own project repository is yours — merge what you like there. Changes to `platform`, `actions`
or `portfolio` need a review, because they affect everyone's deployments.
