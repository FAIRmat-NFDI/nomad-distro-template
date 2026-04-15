#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
from pathlib import Path

TEMPLATE_REPOSITORY = "FAIRmat-NFDI/nomad-distro-template"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Apply README initialization markers for a generated repository."
    )
    parser.add_argument("--readme-path", default="README.md")
    parser.add_argument("--repository", default=TEMPLATE_REPOSITORY)
    parser.add_argument(
        "--keep-markers",
        action="store_true",
        help="Preserve INIT and TEMPLATE-ONLY markers in the output for local preview runs.",
    )
    return parser.parse_args()


def replace_marked_regions(
    text: str,
    replacements: dict[str, str],
    template_values: dict[str, str],
    keep_markers: bool = False,
) -> str:
    block_pattern = re.compile(
        r"(?ms)^(?P<indent>[ \t]*)(?P<open><!-- INIT:replace (?P<targets>[a-z_ ]+) -->)\n"
        r"(?P<body>.*?\n)"
        r"(?P=indent)(?P<close><!-- INIT:replace-end -->)(?P<suffix>\n?)"
    )
    inline_pattern = re.compile(
        r"(?P<open><!-- INIT:replace (?P<targets>[a-z_ ]+) -->)"
        r"(?P<body>.*?)"
        r"(?P<close><!-- INIT:replace-end -->)",
        re.DOTALL,
    )

    def apply_replacements(match: re.Match[str]) -> str:
        body = match.group("body")
        targets = match.group("targets").split()
        for target in targets:
            try:
                template_value = template_values[target]
                replacement_value = replacements[target]
            except KeyError as exc:
                raise RuntimeError(f"Unknown INIT replacement target: {target}") from exc
            body = body.replace(template_value, replacement_value)
        if keep_markers:
            indent = match.groupdict().get("indent", "")
            suffix = match.groupdict().get("suffix", "")
            return (
                f"{indent}{match.group('open')}\n{body}{indent}{match.group('close')}{suffix}"
                if "indent" in match.groupdict()
                else f"{match.group('open')}{body}{match.group('close')}"
            )
        return body

    text = block_pattern.sub(apply_replacements, text)
    return inline_pattern.sub(apply_replacements, text)


def remove_template_only(text: str, keep_markers: bool = False) -> str:
    if keep_markers:
        return text
    pattern = re.compile(r"(?ms)^<!-- TEMPLATE-ONLY:START -->\n.*?\n<!-- TEMPLATE-ONLY:END -->\n?")
    updated, count = pattern.subn("", text)
    if count != 1:
        raise RuntimeError(f"Expected exactly one TEMPLATE-ONLY block, found {count}.")
    return updated


def parse_repository(repository: str) -> tuple[str, str]:
    repository_owner, separator, repository_name = repository.partition("/")
    if not separator or not repository_owner or not repository_name or "/" in repository_name:
        raise RuntimeError(
            f"Expected repository in <owner>/<repo> format, got {repository!r}."
        )
    return repository_owner, repository_name


def build_values(repository: str) -> dict[str, str]:
    repository_owner, repository_name = parse_repository(repository)
    return {
        "repository": repository,
        "repository_owner": repository_owner,
        "repository_name": repository_name,
        "image_name": repository.lower(),
    }


def main() -> int:
    args = parse_args()
    readme_path = Path(args.readme_path)
    repository = args.repository
    replacements = build_values(repository)
    template_values = build_values(TEMPLATE_REPOSITORY)

    text = readme_path.read_text(encoding="utf-8")
    text = remove_template_only(text, keep_markers=args.keep_markers)
    text = replace_marked_regions(
        text,
        replacements,
        template_values,
        keep_markers=args.keep_markers,
    )

    if not args.keep_markers and ("<!-- INIT:" in text or "<!-- TEMPLATE-ONLY:" in text):
        raise RuntimeError("Initialization markers remain in the rendered README.")

    readme_path.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
