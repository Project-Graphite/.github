<div align="center">

# Project Graphite

**A place where things get built, and stay built.**

[project-graphite.com](https://project-graphite.com)

</div>

---

### What this is

Every project built here gets its own repository. Deployable web projects get a subdomain and a
real deployment; libraries, desktop tools and work in progress are labelled honestly. The
Graphite Hub is generated from the same registry that describes deployment state.

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

A top-level folder containing a `Dockerfile` is a service. CI uses that convention to decide what
to lint, build and publish, so adding a service means adding a folder and, for a deployed project,
listing it in `compose.production.yaml`.

Projects created from the template call the shared workflows in `actions`, so the build and deploy
path is defined once and improvements reach every project that uses them.

### Adding a project

1. Create your repository from the project template.
2. Build it. Give each deployable folder a `Dockerfile`.
3. Fill in its `.graphite.yml` with a name, summary, status and deployment, and push it to `main`.
4. Once the entry validates, a listed project gets a card on the site. A deployable project gets
   its subdomain and deployment when it is set up on the shared host.

Full instructions are in [CONTRIBUTING.md](https://github.com/project-graphite/.github/blob/main/CONTRIBUTING.md).

### The bar

A project is listed once it has a README that explains what it is and instructions someone else
could follow to run it. Deployable projects add a screenshot and live link before being marked
`live`. Work in progress and source-only projects are welcome and labelled as such. Abandoned
work is labelled too, rather than quietly deleted — the record is more useful when honest than
tidy.
