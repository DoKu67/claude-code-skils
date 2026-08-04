#!/usr/bin/env python3
"""Print a static function call tree for Python source.

Read-only by construction: the target code is parsed with `ast`, never imported
and never executed, so nothing in the analyzed project can run or be modified.
"""

from __future__ import annotations

import argparse
import ast
import json
import signal
import sys
from dataclasses import dataclass, field
from pathlib import Path

SKIP_DIRECTORY_NAMES = {
    ".git", "__pycache__", ".venv", "venv", "env", ".env", "node_modules",
    ".mypy_cache", ".pytest_cache", ".ruff_cache", ".tox", ".eggs",
    "build", "dist", "site-packages",
}


@dataclass
class FunctionInfo:
    key: str
    simple_name: str
    qualified_name: str
    relative_path: str
    line_number: int
    parameters: str
    return_annotation: str
    has_explicit_return: bool
    is_generator: bool
    description: str
    is_method: bool
    called_names: list[str] = field(default_factory=list)
    resolved_children: list[str] = field(default_factory=list)
    unresolved_calls: list[str] = field(default_factory=list)
    ambiguous_calls: dict[str, int] = field(default_factory=dict)

    @property
    def signature(self) -> str:
        return_part = f" -> {self.return_annotation}" if self.return_annotation else ""
        return f"({self.parameters}){return_part}"


def collect_python_files(input_paths: list[Path]) -> list[Path]:
    """Expand the requested files and folders into a deduplicated list of .py files."""
    collected: list[Path] = []
    for input_path in input_paths:
        if not input_path.exists():
            sys.exit(f"error: path does not exist: {input_path}")
        if input_path.is_file():
            if input_path.suffix != ".py":
                sys.exit(f"error: not a Python file: {input_path}")
            collected.append(input_path)
            continue
        for candidate in sorted(input_path.rglob("*.py")):
            if any(part in SKIP_DIRECTORY_NAMES for part in candidate.parts):
                continue
            collected.append(candidate)

    seen: set[Path] = set()
    unique_files: list[Path] = []
    for file_path in collected:
        resolved = file_path.resolve()
        if resolved in seen:
            continue
        seen.add(resolved)
        unique_files.append(file_path)

    if not unique_files:
        sys.exit("error: no Python files found in the requested scope")
    return unique_files


def iter_nested_statements(body: list[ast.stmt]) -> list[ast.stmt]:
    """Yield statements in a body, descending through if/try/with/loop blocks.

    Definitions guarded by `if TYPE_CHECKING:` or wrapped in try/except still
    define real functions, so they must not be missed.
    """
    statements: list[ast.stmt] = []
    for statement in body:
        statements.append(statement)
        for attribute_name in ("body", "orelse", "finalbody"):
            nested = getattr(statement, attribute_name, None)
            if isinstance(nested, list) and not isinstance(statement, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
                statements.extend(iter_nested_statements(nested))
        for handler in getattr(statement, "handlers", []):
            statements.extend(iter_nested_statements(handler.body))
    return statements


def build_parameters(node: ast.FunctionDef | ast.AsyncFunctionDef) -> str:
    return ast.unparse(node.args)


def build_return_annotation(node: ast.FunctionDef | ast.AsyncFunctionDef) -> str:
    return ast.unparse(node.returns) if node.returns else ""


def collect_return_info(node: ast.FunctionDef | ast.AsyncFunctionDef) -> tuple[bool, bool]:
    """Report whether this function returns a value and whether it is a generator.

    Nested definitions are skipped so their returns are not attributed to the parent.
    """
    has_explicit_return = False
    is_generator = False

    def walk(current: ast.AST) -> None:
        nonlocal has_explicit_return, is_generator
        if isinstance(current, ast.Return) and current.value is not None:
            has_explicit_return = True
        if isinstance(current, (ast.Yield, ast.YieldFrom)):
            is_generator = True
        for child in ast.iter_child_nodes(current):
            if isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
                continue
            walk(child)

    for statement in node.body:
        if isinstance(statement, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            continue
        walk(statement)

    return has_explicit_return, is_generator


def callee_name(node: ast.expr) -> str | None:
    """Return the bare name being called, e.g. `parse` for both `parse()` and `self.parse()`."""
    if isinstance(node, ast.Name):
        return node.id
    if isinstance(node, ast.Attribute):
        return node.attr
    return None


def collect_called_names(node: ast.FunctionDef | ast.AsyncFunctionDef) -> list[str]:
    """Collect names called directly in this function, excluding nested definitions."""
    called: list[str] = []

    def walk(current: ast.AST) -> None:
        for child in ast.iter_child_nodes(current):
            if isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
                continue
            if isinstance(child, ast.Call):
                name = callee_name(child.func)
                if name:
                    called.append(name)
            walk(child)

    for statement in node.body:
        walk(statement)

    ordered_unique: list[str] = []
    for name in called:
        if name not in ordered_unique:
            ordered_unique.append(name)
    return ordered_unique


def extract_functions(file_path: Path, base_directory: Path) -> list[FunctionInfo]:
    source_text = file_path.read_text(encoding="utf-8", errors="replace")
    try:
        module = ast.parse(source_text)
    except SyntaxError as syntax_error:
        print(f"warning: skipping {file_path} (syntax error line {syntax_error.lineno})", file=sys.stderr)
        return []

    try:
        relative_path = str(file_path.resolve().relative_to(base_directory))
    except ValueError:
        relative_path = str(file_path)

    functions: list[FunctionInfo] = []

    def visit_body(body: list[ast.stmt], name_prefix: str, inside_class: bool) -> None:
        for statement in iter_nested_statements(body):
            if isinstance(statement, ast.ClassDef):
                visit_body(statement.body, f"{name_prefix}{statement.name}.", inside_class=True)
            elif isinstance(statement, (ast.FunctionDef, ast.AsyncFunctionDef)):
                qualified_name = f"{name_prefix}{statement.name}"
                docstring = ast.get_docstring(statement)
                summary = docstring.strip().splitlines()[0].strip() if docstring else ""
                has_explicit_return, is_generator = collect_return_info(statement)
                functions.append(
                    FunctionInfo(
                        key=f"{relative_path}::{qualified_name}",
                        simple_name=statement.name,
                        qualified_name=qualified_name,
                        relative_path=relative_path,
                        line_number=statement.lineno,
                        parameters=build_parameters(statement),
                        return_annotation=build_return_annotation(statement),
                        has_explicit_return=has_explicit_return,
                        is_generator=is_generator,
                        description=summary,
                        is_method=inside_class,
                        called_names=collect_called_names(statement),
                    )
                )
                visit_body(statement.body, f"{qualified_name}.", inside_class=False)

    visit_body(module.body, "", inside_class=False)
    return functions


def resolve_call_edges(functions: list[FunctionInfo]) -> None:
    """Match each called name to in-scope definitions and record the outcome."""
    by_simple_name: dict[str, list[FunctionInfo]] = {}
    for function in functions:
        by_simple_name.setdefault(function.simple_name, []).append(function)

    for function in functions:
        for called in function.called_names:
            candidates = by_simple_name.get(called, [])
            if not candidates:
                function.unresolved_calls.append(called)
            elif len(candidates) == 1:
                function.resolved_children.append(candidates[0].key)
            else:
                function.ambiguous_calls[called] = len(candidates)
                function.resolved_children.extend(candidate.key for candidate in candidates)


def find_root_functions(functions: list[FunctionInfo]) -> list[FunctionInfo]:
    """Roots are functions nothing else in scope calls — the entry points of the tree."""
    called_keys: set[str] = set()
    for function in functions:
        # Self-recursion does not make a function a non-root.
        called_keys.update(child for child in function.resolved_children if child != function.key)

    roots = [function for function in functions if function.key not in called_keys]
    if not roots:
        # Every function participates in a cycle; fall back to module-level functions.
        roots = [function for function in functions if "." not in function.qualified_name]
    if not roots:
        roots = list(functions)
    return sorted(roots, key=lambda function: (function.relative_path, function.line_number))


class TreeRenderer:
    def __init__(
        self,
        functions_by_key: dict[str, FunctionInfo],
        max_depth: int,
        max_nodes: int,
        show_external: bool,
        repeat_subtrees: bool,
        compact: bool,
    ) -> None:
        self.functions_by_key = functions_by_key
        self.max_depth = max_depth
        self.max_nodes = max_nodes
        self.show_external = show_external
        self.repeat_subtrees = repeat_subtrees
        self.compact = compact
        self.lines: list[str] = []
        self.node_count = 0
        self.expanded_keys: set[str] = set()
        self.truncated = False

    def build_detail_block(self, function: FunctionInfo, child_prefix: str) -> list[str]:
        """Render the Input/Output detail lines shown beneath a function name."""
        parameters = function.parameters if function.parameters else ""
        block = [f"{child_prefix}Input: ({parameters})"]
        block.append(f"{child_prefix}  * {function.relative_path}:{function.line_number}")

        if function.return_annotation:
            output_label = function.return_annotation
        elif function.has_explicit_return:
            output_label = "(unannotated)"
        else:
            output_label = "None"
        if function.is_generator:
            output_label = f"{output_label}  (generator)"

        block.append(f"{child_prefix}Output: {output_label}")
        return block

    def render_function(self, key: str, prefix: str, is_last: bool, ancestor_keys: tuple[str, ...]) -> None:
        if self.node_count >= self.max_nodes:
            self.truncated = True
            return

        function = self.functions_by_key[key]
        connector = "└── " if is_last else "├── "
        child_prefix = prefix + ("    " if is_last else "│   ")

        suffix = ""
        if key in ancestor_keys:
            suffix = "  ⟲ recursive"
        elif not self.repeat_subtrees and key in self.expanded_keys and function.resolved_children:
            suffix = "  ⟲ expanded above"

        if self.compact:
            location = f"  [{function.relative_path}:{function.line_number}]"
            self.lines.append(f"{prefix}{connector}{function.qualified_name}{function.signature}{location}{suffix}")
        else:
            self.lines.append(f"{prefix}{connector}{function.qualified_name}{suffix}")
        self.node_count += 1

        if function.description and not suffix:
            self.lines.append(f"{child_prefix}# {function.description}")

        if not self.compact and not suffix:
            self.lines.extend(self.build_detail_block(function, child_prefix))

        if suffix or len(ancestor_keys) + 1 >= self.max_depth:
            if not suffix and function.resolved_children:
                self.lines.append(f"{child_prefix}└── … depth limit reached")
            return

        self.expanded_keys.add(key)

        children: list[tuple[str, str]] = []
        for child_key in dict.fromkeys(function.resolved_children):
            child = self.functions_by_key[child_key]
            marker = ""
            if child.simple_name in function.ambiguous_calls:
                marker = f"  ? one of {function.ambiguous_calls[child.simple_name]} definitions"
            children.append((child_key, marker))

        external_children: list[str] = []
        if self.show_external:
            external_children = list(dict.fromkeys(function.unresolved_calls))

        total_children = len(children) + len(external_children)
        for index, (child_key, marker) in enumerate(children):
            child_is_last = index == total_children - 1
            before = len(self.lines)
            self.render_function(child_key, child_prefix, child_is_last, ancestor_keys + (key,))
            if marker and len(self.lines) > before:
                self.lines[before] += marker

        for offset, external_name in enumerate(external_children):
            child_is_last = len(children) + offset == total_children - 1
            child_connector = "└── " if child_is_last else "├── "
            self.lines.append(f"{child_prefix}{child_connector}{external_name}(…)  [external]")
            self.node_count += 1


def render_tree(functions: list[FunctionInfo], roots: list[FunctionInfo], arguments: argparse.Namespace) -> str:
    functions_by_key = {function.key: function for function in functions}
    renderer = TreeRenderer(
        functions_by_key=functions_by_key,
        max_depth=arguments.depth,
        max_nodes=arguments.max_nodes,
        show_external=arguments.include_external,
        repeat_subtrees=arguments.repeat_subtrees,
        compact=arguments.compact,
    )

    output_lines: list[str] = []
    current_file = ""
    roots_by_file: dict[str, list[FunctionInfo]] = {}
    for root in roots:
        roots_by_file.setdefault(root.relative_path, []).append(root)

    for file_path, file_roots in roots_by_file.items():
        if current_file:
            output_lines.append("")
        current_file = file_path
        output_lines.append(file_path)
        for index, root in enumerate(file_roots):
            renderer.lines = []
            renderer.render_function(root.key, "", index == len(file_roots) - 1, ())
            output_lines.extend(renderer.lines)

    file_count = len({function.relative_path for function in functions})
    summary_parts = [
        f"{file_count} file" + ("s" if file_count != 1 else ""),
        f"{len(functions)} function" + ("s" if len(functions) != 1 else ""),
        f"{len(roots)} entry point" + ("s" if len(roots) != 1 else ""),
    ]
    unresolved_total = sum(len(set(function.unresolved_calls)) for function in functions)
    if unresolved_total and not arguments.include_external:
        summary_parts.append(f"{unresolved_total} external/unresolved calls hidden (--include-external to show)")
    output_lines.append("")
    output_lines.append("— " + ", ".join(summary_parts))
    if renderer.truncated:
        output_lines.append(
            f"— output truncated at {arguments.max_nodes} nodes; narrow the scope or lower --depth"
        )
    return "\n".join(output_lines)


def apply_annotations(functions: list[FunctionInfo], annotations_path: Path) -> None:
    """Overlay human/model-written descriptions keyed by `relative/path.py::qualified.name`."""
    annotations = json.loads(annotations_path.read_text(encoding="utf-8"))
    for function in functions:
        if function.key in annotations:
            function.description = str(annotations[function.key]).strip()


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Print a static function call tree for Python files or folders.",
    )
    parser.add_argument("paths", nargs="+", type=Path, help="files and/or folders to analyze")
    parser.add_argument("--depth", type=int, default=6, help="maximum tree depth (default: 6)")
    parser.add_argument("--max-nodes", type=int, default=400, help="stop after this many nodes (default: 400)")
    parser.add_argument("--compact", action="store_true", help="one line per function instead of Input/Output blocks")
    parser.add_argument("--include-external", action="store_true", help="show calls to code outside the scope")
    parser.add_argument("--repeat-subtrees", action="store_true", help="re-expand functions that appear more than once")
    parser.add_argument("--annotations", type=Path, help="JSON file of key -> description overrides")
    parser.add_argument("--json", action="store_true", help="emit the raw graph as JSON instead of a tree")
    parser.add_argument("--list-undocumented", action="store_true", help="list keys of functions with no docstring")
    parser.add_argument("--base", type=Path, default=Path.cwd(), help="base directory for relative paths")
    return parser.parse_args()


def main() -> None:
    if hasattr(signal, "SIGPIPE"):
        # Piping into `head` or `less` closes stdout early; exit quietly instead of raising.
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)

    arguments = parse_arguments()
    base_directory = arguments.base.resolve()
    python_files = collect_python_files(arguments.paths)

    functions: list[FunctionInfo] = []
    for file_path in python_files:
        functions.extend(extract_functions(file_path, base_directory))

    if not functions:
        sys.exit("error: no function definitions found in the requested scope")

    resolve_call_edges(functions)

    if arguments.annotations:
        apply_annotations(functions, arguments.annotations)

    if arguments.list_undocumented:
        for function in functions:
            if not function.description:
                print(function.key)
        return

    if arguments.json:
        payload = [
            {
                "key": function.key,
                "qualified_name": function.qualified_name,
                "file": function.relative_path,
                "line": function.line_number,
                "parameters": function.parameters,
                "return_annotation": function.return_annotation,
                "has_explicit_return": function.has_explicit_return,
                "is_generator": function.is_generator,
                "description": function.description,
                "is_method": function.is_method,
                "calls_in_scope": function.resolved_children,
                "calls_external": sorted(set(function.unresolved_calls)),
            }
            for function in functions
        ]
        print(json.dumps(payload, indent=2))
        return

    roots = find_root_functions(functions)
    print(render_tree(functions, roots, arguments))


if __name__ == "__main__":
    main()
