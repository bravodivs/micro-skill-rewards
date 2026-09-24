# Momentum content engine

This directory is a standalone scaffold. Move it into its own private GitHub
repository; it validates curated cards and publishes them to a separate public
catalog repository in immutable batches of 10.

## Repositories

1. **Content engine (private):** this directory, source drafts, workflow, write
   token.
2. **Catalog (public):** `manifest.json` and `batches/*.json`; read directly by
   the Flutter app without credentials.

Never put the catalog write token in the mobile application.

## Local run

Install [uv](https://docs.astral.sh/uv/), clone the public catalog beside this
repo, and run:

```bash
uv run momentum-publish \
  --input content/cards.json \
  --catalog ../momentum-catalog \
  --weekly-limit 350
```

Only IDs not already present in the catalog are appended. The input count must
be divisible by the catalog's `batchSize` (10). Existing batches are never
rewritten.

## Weekly automation

Copy `.github/workflows/publish-weekly.yml` into the engine repo, then set:

- Repository variable `CATALOG_REPOSITORY`: `owner/momentum-catalog`
- Secret `CATALOG_WRITE_TOKEN`: fine-grained GitHub token with Contents write
  permission on only the public catalog repo

The job runs every Monday and can also be started with `workflow_dispatch`.

The initial public catalog can be created by copying
`../assets/catalog/manifest.json` and `../assets/catalog/batches/` from the app
repo.
