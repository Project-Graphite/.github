<div align="center">

# Project Graphite

**A place where things get built, and stay built.**

[project-graphite.com](https://project-graphite.com)

</div>

---

### What this is

Every project built here gets its own repository, its own subdomain and a real deployment — not a
screenshot and a dead link. The portfolio is generated from what is actually running.

It started as one person's way of keeping a track record, and is open to people they work with.
Projects keep their authors' names on them.

### How it works

One repository per project. A project that has a front end, an API and a worker keeps all three in
the same repository, in separate folders — not spread across three repositories.

```
my-project/
├── frontend/Dockerfile
├── server/Dockerfile
└── worker/Dockerfile
```

A top-level folder containing a `Dockerfile` is a service. That single convention is what CI uses
to decide what to lint, what to build and what to deploy, so adding a service means adding a
folder and nothing else.

Projects do not write their own pipelines. They call shared workflows, so the build and deploy
path is defined once and improvements reach every repository at the same time.

### Adding a project

1. Create your repository from the project template.
2. Build it. Give each deployable folder a `Dockerfile`.
3. Open a pull request registering it, with a name, a one-line summary and the resources it needs.
4. On merge it gets a subdomain, a deployment, and a card on the site.

Full instructions are in [CONTRIBUTING.md](https://github.com/project-graphite/.github/blob/main/CONTRIBUTING.md).

### The bar

A project is listed once it has a README that explains what it is, a screenshot, a live link, and
instructions someone else could follow to run it. Work in progress is welcome and is labelled as
such. Abandoned work is labelled too, rather than quietly deleted — the record is more useful
honest than tidy.
