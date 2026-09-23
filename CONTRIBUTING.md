# Contributing

## Adding a project

**1. Create the repository.** Start from
[project-template](https://github.com/project-graphite/project-template) — use *Use this template*,
not a fork. It carries the CI wiring, the compose setup and the layout conventions.

The template and platform registry are private to organisation members. If either link returns
404, ask a maintainer to add you to the `contributors` team before continuing.

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

**4. Write the README.** Explain what it is, the stack and how to run it locally. Add a screenshot
or short GIF when the project has a visual interface, and add the live link before marking a
deployable project `live`. This is what people actually read.

**5. Register it.** Edit `.graphite.yml` at the repository root. The template's copy registers
`project-template` itself, so set `slug` to the repository name and replace the rest of the entry
with your project's details. The comments in the file describe every field. When the file changes
on `main`, the `Registry` workflow asks [`platform`](https://github.com/project-graphite/platform)
to sync it into `projects/<slug>.yml`, and the entry is merged once it validates.

Until that entry is merged, CI builds and checks run normally and only the deploy step is blocked,
with a message saying so.

## Conventions

**Pull request titles** follow `type(scope): summary`, using one of `feat fix chore refactor docs
test ci perf revert style build`. Squash-merge with the pull request title as the commit title on
`main`.

**Pull requests get a size label** based on changed lines, excluding lockfiles. Large ones are not
blocked, but they are slower to review and more likely to sit.

**Secrets never go in a repository.** The registry entry names the environment variables a service
needs; the values live on the host. Pull requests in repositories made from the template are
scanned with Gitleaks, and a committed secret fails their `Secrets` check.

## Reviews

Your own project repository is yours — merge what you like there. Changes to `platform`, `actions`
or `graphite-hub` need a review, because they affect everyone's deployments.
