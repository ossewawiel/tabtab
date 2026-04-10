# `docs/_source/`

Original source documents for the TabTab architecture. The markdown files in
`docs/architecture/` are converted from these using `scripts/docx_to_md.py`.

Keep these around so we can:
1. Re-run the converter if it improves (better table handling, code-block
   detection, etc.)
2. Diff against the converted markdown to verify fidelity
3. Hand the originals to reviewers who prefer Word

**The converted markdown in `docs/architecture/` is the canonical version for
implementation work.** If these source docs and the markdown diverge, the
markdown wins and these files should be re-exported from it (or updated
manually).

## Files

| Source | Converted to |
|---|---|
| `TabTab_Architecture_Document.docx` | `docs/architecture/architecture.md` |
| `TabTab_YAML_Schema_Specification.docx` | `docs/architecture/yaml-schema.md` |
| `TabTab_Signal_System_Specification.docx` | `docs/architecture/signal-system.md` |
| `TabTab_Component_Library_Specification.docx` | `docs/architecture/component-library.md` |
| `TabTab_Code_Generation_Pipeline.docx` | `docs/architecture/code-generation.md` |
| `TabTab_Project_Bootstrap_Specification.md` | _(this entire repo — it's the blueprint that scaffolded everything)_ |

## Re-converting

```bash
python scripts/docx_to_md.py docs/_source/TabTab_Architecture_Document.docx docs/architecture/architecture.md
# ... etc
```
