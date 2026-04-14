#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

TEMPLATE_ONLY_BLOCK_RE = re.compile(
    r"(?ms)^<!-- TEMPLATE-ONLY:START -->\n(.*?)^<!-- TEMPLATE-ONLY:END -->\n?"
)
PLACEHOLDER_RE = re.compile(r"\{\{\s*([A-Z_]+)\s*\}\}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render README.md from README.template.md."
    )
    parser.add_argument(
        "--repository",
        default="FAIRmat-NFDI/nomad-distro-template",
        help="Repository in owner/name form.",
    )
    parser.add_argument(
        "--template-path",
        default="README.template.md",
        help="Path to the README template file.",
    )
    parser.add_argument(
        "--output-path",
        default="README.md",
        help="Path to the rendered README file.",
    )
    parser.add_argument(
        "--include-template-section",
        action="store_true",
        help="Keep template-only content in the rendered README.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Exit with a non-zero status if the rendered README differs from the output.",
    )
    return parser.parse_args()


def parse_repository(repository: str) -> tuple[str, str]:
    owner, separator, name = repository.partition("/")
    if not separator or not owner or not name:
        raise ValueError(
            f"Expected --repository in owner/name form, received: {repository!r}"
        )
    return owner, name


def render_template_only_blocks(content: str, include_template_section: bool) -> str:
    def replace(match: re.Match[str]) -> str:
        return match.group(1) if include_template_section else ""

    return TEMPLATE_ONLY_BLOCK_RE.sub(replace, content)


def render_placeholders(content: str, replacements: dict[str, str]) -> str:
    def replace(match: re.Match[str]) -> str:
        placeholder = match.group(1)
        try:
            return replacements[placeholder]
        except KeyError as exc:
            raise ValueError(f"Unknown README placeholder: {placeholder}") from exc

    rendered = PLACEHOLDER_RE.sub(replace, content)
    unresolved = sorted(set(PLACEHOLDER_RE.findall(rendered)))
    if unresolved:
        joined = ", ".join(unresolved)
        raise ValueError(f"Unresolved README placeholders remain: {joined}")
    return rendered


def main() -> int:
    args = parse_args()
    repository_owner, repository_name = parse_repository(args.repository)
    replacements = {
        "REPOSITORY": args.repository,
        "REPOSITORY_OWNER": repository_owner,
        "REPOSITORY_NAME": repository_name,
        "IMAGE_NAME": args.repository.lower(),
    }

    template_path = Path(args.template_path)
    output_path = Path(args.output_path) if args.output_path != "-" else None
    template = template_path.read_text(encoding="utf-8")
    rendered = render_template_only_blocks(
        template, include_template_section=args.include_template_section
    )
    rendered = render_placeholders(rendered, replacements)

    if args.check:
        if output_path is None:
            raise ValueError("--check cannot be used together with --output-path -")
        current = output_path.read_text(encoding="utf-8")
        if current != rendered:
            print(
                f"{output_path} is out of date. Re-run scripts/render_readme.py to update it.",
                file=sys.stderr,
            )
            return 1
        return 0

    if output_path is None:
        sys.stdout.write(rendered)
        return 0

    output_path.write_text(rendered, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
