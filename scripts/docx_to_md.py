"""
Convert a .docx file to a reasonable GitHub-flavored markdown rendering.

This is a pragmatic converter — good enough to ship the architecture docs into
docs/architecture/ without losing structure. It handles:
  - Headings (Heading 1..6)
  - Paragraphs (with bold/italic runs)
  - Lists (bulleted and numbered, nested by indent/level)
  - Tables (as GFM pipe tables)
  - Code blocks (paragraphs in a monospace style OR 'Intense Quote' / 'Code' style)
  - Inline code (runs with a monospace font)

It does NOT handle: images, equations, comments, revision marks, embedded objects.
These are rare in our architecture docs.

Usage:
    python scripts/docx_to_md.py <input.docx> <output.md>
"""

from __future__ import annotations

import sys
from pathlib import Path

from docx import Document
from docx.oxml.ns import qn
from docx.table import Table
from docx.text.paragraph import Paragraph

MONOSPACE_FONTS = {
    "consolas", "courier new", "courier", "menlo", "monaco",
    "lucida console", "source code pro", "fira code", "cascadia code",
    "jetbrains mono", "roboto mono",
}


def iter_block_items(parent):
    """Yield paragraphs and tables in document order."""
    body = parent.element.body
    for child in body.iterchildren():
        if child.tag == qn("w:p"):
            yield Paragraph(child, parent)
        elif child.tag == qn("w:tbl"):
            yield Table(child, parent)


def run_is_monospace(run) -> bool:
    name = None
    rpr = run._element.rPr
    if rpr is not None:
        rfonts = rpr.find(qn("w:rFonts"))
        if rfonts is not None:
            name = rfonts.get(qn("w:ascii")) or rfonts.get(qn("w:hAnsi"))
    if not name and run.font and run.font.name:
        name = run.font.name
    return bool(name) and name.strip().lower() in MONOSPACE_FONTS


def escape_md(text: str) -> str:
    # Escape characters that would otherwise be interpreted by markdown.
    # Keep the set small — over-escaping makes the output unreadable.
    return (text
            .replace("\\", "\\\\")
            .replace("`", "\\`")
            .replace("*", "\\*")
            .replace("_", "\\_")
            .replace("<", "&lt;")
            .replace(">", "&gt;"))


def render_runs(paragraph: Paragraph) -> str:
    """Render a paragraph's runs into inline markdown."""
    parts: list[str] = []
    for run in paragraph.runs:
        text = run.text
        if not text:
            continue
        mono = run_is_monospace(run)
        if mono:
            # Inline code. Don't escape inside backticks.
            parts.append(f"`{text}`")
            continue
        text = escape_md(text)
        if run.bold and run.italic:
            text = f"***{text}***"
        elif run.bold:
            text = f"**{text}**"
        elif run.italic:
            text = f"*{text}*"
        parts.append(text)
    return "".join(parts).strip()


def style_name(paragraph: Paragraph) -> str:
    st = paragraph.style
    return ((st.name if st is not None else "") or "").lower()


def heading_level(paragraph: Paragraph) -> int | None:
    style = style_name(paragraph)
    if style.startswith("heading "):
        try:
            return int(style.split()[-1])
        except ValueError:
            return None
    if style == "title":
        return 1
    return None


def list_info(paragraph: Paragraph) -> tuple[bool, bool, int]:
    """
    Return (is_list, is_numbered, indent_level).
    Detected via the paragraph's numbering properties or its style name.
    """
    pPr = paragraph._element.pPr
    if pPr is not None:
        numPr = pPr.find(qn("w:numPr"))
        if numPr is not None:
            ilvl_el = numPr.find(qn("w:ilvl"))
            ilvl = int(ilvl_el.get(qn("w:val"))) if ilvl_el is not None else 0
            # We can't reliably tell bullet vs numbered without the numbering
            # definition. Use the style name as a hint.
            style = style_name(paragraph)
            is_numbered = "number" in style or "decimal" in style
            return (True, is_numbered, ilvl)
    style = style_name(paragraph)
    if "list bullet" in style:
        level = 0
        # "List Bullet 2" → indent level 1
        tail = style.replace("list bullet", "").strip()
        if tail.isdigit():
            level = int(tail) - 1
        return (True, False, level)
    if "list number" in style:
        level = 0
        tail = style.replace("list number", "").strip()
        if tail.isdigit():
            level = int(tail) - 1
        return (True, True, level)
    return (False, False, 0)


def paragraph_is_code_block(paragraph: Paragraph) -> bool:
    style = style_name(paragraph)
    if style in {"code", "source code", "html preformatted", "preformatted text"}:
        return True
    if not paragraph.runs:
        return False
    # If every non-empty run is monospace, treat as code line.
    mono_runs = [r for r in paragraph.runs if r.text]
    if not mono_runs:
        return False
    return all(run_is_monospace(r) for r in mono_runs)


def render_table(table: Table) -> list[str]:
    """Render a python-docx Table as a GFM pipe table."""
    rows = []
    for row in table.rows:
        cells = []
        for cell in row.cells:
            # Flatten the cell's paragraphs into one line.
            cell_text_parts = []
            for p in cell.paragraphs:
                txt = render_runs(p)
                if txt:
                    cell_text_parts.append(txt)
            cell_text = " <br> ".join(cell_text_parts)
            cell_text = cell_text.replace("|", "\\|")
            cells.append(cell_text or " ")
        rows.append(cells)

    if not rows:
        return []

    # Pad rows to the max column count (merged cells can cause variable width).
    ncols = max(len(r) for r in rows)
    for r in rows:
        while len(r) < ncols:
            r.append(" ")

    out = []
    out.append("| " + " | ".join(rows[0]) + " |")
    out.append("|" + "|".join(["---"] * ncols) + "|")
    for r in rows[1:]:
        out.append("| " + " | ".join(r) + " |")
    return out


def convert(input_path: Path, output_path: Path) -> None:
    doc = Document(str(input_path))
    lines: list[str] = []
    in_code_block = False

    def close_code_block():
        nonlocal in_code_block
        if in_code_block:
            lines.append("```")
            lines.append("")
            in_code_block = False

    for block in iter_block_items(doc):
        if isinstance(block, Table):
            close_code_block()
            lines.extend(render_table(block))
            lines.append("")
            continue

        paragraph = block

        # Code block
        if paragraph_is_code_block(paragraph):
            if not in_code_block:
                lines.append("```")
                in_code_block = True
            lines.append(paragraph.text)
            continue
        else:
            close_code_block()

        # Heading
        lvl = heading_level(paragraph)
        if lvl:
            text = render_runs(paragraph)
            if text:
                lines.append("#" * min(lvl, 6) + " " + text)
                lines.append("")
            continue

        # List item
        is_list, is_numbered, indent = list_info(paragraph)
        if is_list:
            text = render_runs(paragraph)
            if text:
                prefix = ("  " * indent) + ("1. " if is_numbered else "- ")
                lines.append(prefix + text)
            continue

        # Plain paragraph
        text = render_runs(paragraph)
        if text:
            lines.append(text)
            lines.append("")

    close_code_block()

    # Collapse runs of blank lines.
    cleaned: list[str] = []
    blank = False
    for line in lines:
        if line.strip() == "":
            if not blank:
                cleaned.append("")
            blank = True
        else:
            cleaned.append(line)
            blank = False

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(cleaned).rstrip() + "\n", encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: python docx_to_md.py <input.docx> <output.md>", file=sys.stderr)
        return 2
    convert(Path(sys.argv[1]), Path(sys.argv[2]))
    print(f"wrote {sys.argv[2]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
