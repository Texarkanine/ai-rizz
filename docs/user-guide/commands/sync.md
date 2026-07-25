# sync

```bash
ai-rizz sync
```

Pulls down updates to your [local cache](../../developer-guide/rules-cache.md) of the rule source for the current repository, then updates all rules in use in the current repository.

If a standalone entry in your manifest still points at an old path (for example `rules/foo.mdc`) but upstream relocated the same name-slug to another form (`rules/foo.md` command or `rules/foo/` skill), sync rewrites that manifest line to the current path and deploys the new form. Truly missing slugs still warn and stay in the manifest.
