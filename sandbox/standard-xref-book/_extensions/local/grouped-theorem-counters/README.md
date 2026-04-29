# grouped-theorem-counters

Minimal Quarto extension for grouping theorem-like block counters while keeping standard `@id` references.

## What it does

- Lets multiple block classes share one counter within each chapter.
- Rewrites grouped block titles and grouped `@id` references to use the shared numbering.
- Keeps standard Quarto syntax in source files (`@thm-foo`, `@lem-bar`, etc.).
- Works for both HTML and PDF book output.

## Configuration example

```yaml
filters:
  - path: _extensions/local/grouped-theorem-counters/grouped-theorem-counters.lua
    at: post-render

grouped-theorem-counters:
  groups:
    theorem_like:
      classes: [theorem, lemma, proposition]
```

## Notes

- The extension only changes classes listed in your groups.
- Non-grouped classes (for example `exercise`) continue using Quarto defaults.
