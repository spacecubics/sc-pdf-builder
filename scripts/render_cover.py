#!/usr/bin/env python3
"""Render an XML-safe cover SVG from a placeholder template."""

from datetime import date
from html import escape
from pathlib import Path
import re
import subprocess
import sys

ATTRIBUTE_TO_PLACEHOLDER = {
    "confidential-label": "CONFIDENTIAL_LABEL",
    "document-number": "DOCUMENT_NUMBER",
    "product-name": "PRODUCT_NAME",
    "cover-footer-text": "COVER_FOOTER_TEXT",
    "date": "FIELD_1_VALUE",
    "revision": "FIELD_2_VALUE",
}

GIT_HASH_SENTINEL = "GITHASH"
BUILD_DATE_SENTINEL = "BUILDDATE"
ENGLISH_MONTH_NAMES = (
    "",
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
)


def read_adoc_attributes(path: Path) -> dict[str, str]:
    attributes: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.match(r"^:([a-z0-9_-]+):(?:\s+(.*))?$", line)
        if match:
            attributes[match.group(1)] = match.group(2) or ""
    return attributes


def resolve_revision(value: str, document: Path) -> str:
    if value != GIT_HASH_SENTINEL:
        return value
    try:
        revision = subprocess.run(
            ["git", "-C", str(document.parent), "rev-parse", "--short=12", "HEAD"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        status = subprocess.run(
            [
                "git",
                "-C",
                str(document.parent),
                "status",
                "--porcelain",
                "--untracked-files=no",
            ],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
    except (FileNotFoundError, subprocess.CalledProcessError) as error:
        raise SystemExit(
            "revision is GITHASH, but the Git commit hash could not be determined"
        ) from error
    return f"{revision}-dirty" if status else revision


def resolve_date(value: str) -> str:
    if value != BUILD_DATE_SENTINEL:
        return value
    build_date = date.today()
    return (
        f"{ENGLISH_MONTH_NAMES[build_date.month]} "
        f"{build_date.day}, {build_date.year}"
    )


def main() -> None:
    if len(sys.argv) != 5 or sys.argv[3] != "--adoc":
        raise SystemExit("usage: render_cover.py TEMPLATE OUTPUT --adoc DOCUMENT")

    source = Path(sys.argv[1]).read_text(encoding="utf-8")
    document = Path(sys.argv[4])
    attributes = read_adoc_attributes(document)
    attributes["date"] = resolve_date(attributes.get("date", ""))
    attributes["revision"] = resolve_revision(
        attributes.get("revision", ""), document
    )
    replacements = {
        "FIELD_1_LABEL": "DATE",
        "FIELD_2_LABEL": "REVISION",
    }
    replacements.update({
        placeholder: attributes.get(attribute, "")
        for attribute, placeholder in ATTRIBUTE_TO_PLACEHOLDER.items()
    })
    for key, value in replacements.items():
        source = source.replace(f"@{key}@", escape(value))
    Path(sys.argv[2]).write_text(source, encoding="utf-8")


if __name__ == "__main__":
    main()
