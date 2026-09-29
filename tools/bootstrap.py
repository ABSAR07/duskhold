#!/usr/bin/env python3
"""Consent-gated, checksum-verified installer for the Duskhold toolchain.

Installs the pinned Godot 4.7.2-stable editor and Windows export templates,
vendors GUT 9.7.1 into addons/gut/, and creates a local venv with gdtoolkit
4.5.0. Standard library only (argparse, urllib.request, hashlib, zipfile,
subprocess, pathlib, shutil, os, sys, platform, stat).

Downloads nothing unless a component flag AND --yes are both passed. With no
component flag, or with --dry-run, it only prints the download table and
touches no network. Run `python tools/bootstrap.py --dry-run` first.
"""
from __future__ import annotations

import argparse
import hashlib
import os
import platform
import shutil
import stat
import subprocess
import sys
import urllib.error
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOLS_DIR = ROOT / "tools"
DOT_TOOLS = ROOT / ".tools"
DOWNLOADS_DIR = DOT_TOOLS / "downloads"
PIN_FILE = TOOLS_DIR / "godot_sha512sums.txt"
VERSION_FILE = TOOLS_DIR / "godot_version.txt"
REQUIREMENTS_LINT_FILE = TOOLS_DIR / "requirements-lint.txt"

USER_AGENT = "duskhold-bootstrap"
GUT_TAG = "v9.7.1"
GUT_ZIP_URL = f"https://github.com/bitwes/Gut/archive/refs/tags/{GUT_TAG}.zip"
GUT_LOCAL_NAME = f"Gut-{GUT_TAG}.zip"

_official_sums_cache: dict[str, str] | None = None


def read_version() -> str:
    return VERSION_FILE.read_text(encoding="utf-8").strip()


VERSION = read_version()
GODOT_RELEASE_BASE = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}/"

ARTIFACTS = {
    "win64_zip": {"name": f"Godot_v{VERSION}_win64.exe.zip", "size": 86_013_866},
    "linux_zip": {"name": f"Godot_v{VERSION}_linux.x86_64.zip", "size": 77_860_424},
    "templates_tpz": {"name": f"Godot_v{VERSION}_export_templates.tpz", "size": 1_281_349_702},
    "sha512_sums": {"name": "SHA512-SUMS.txt", "size": 5_682},
}
GUT_ARTIFACT_SIZE = 1_000_000
LINT_ARTIFACT_SIZE = 10_000_000


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Consent-gated, checksum-verified installer for the Duskhold toolchain "
            "(Godot editor + export templates, GUT, gdtoolkit)."
        )
    )
    parser.add_argument("--dry-run", action="store_true", help="Print the download table and exit 0.")
    parser.add_argument("--godot", action="store_true", help="Install the pinned Godot editor for --platform.")
    parser.add_argument("--templates", action="store_true", help="Install the matching Windows export templates.")
    parser.add_argument("--gut", action="store_true", help="Vendor GUT into addons/gut/.")
    parser.add_argument("--lint-tools", action="store_true", help="Create .tools/venv and install gdtoolkit.")
    parser.add_argument("--all", action="store_true", help="Shorthand for --godot --templates --gut --lint-tools.")
    parser.add_argument("--yes", action="store_true", help="Required to perform any download (owner approval).")
    parser.add_argument(
        "--platform",
        choices=["windows", "linux"],
        default=None,
        help="Target platform for --godot. Defaults to the host platform.",
    )
    parser.add_argument("--force", action="store_true", help="Reinstall/overwrite even if the destination exists.")
    parser.add_argument(
        "--keep-downloads",
        action="store_true",
        help="Keep downloaded archives in .tools/downloads/ instead of deleting them after extraction.",
    )
    parser.add_argument(
        "--write-pin",
        action="store_true",
        help="Write tools/godot_sha512sums.txt from the official SHA512-SUMS.txt for this version.",
    )
    parser.add_argument("--print-godot-path", action="store_true", help="Print the resolved Godot binary path and exit.")
    return parser.parse_args(argv)


def resolve_platform(args: argparse.Namespace) -> str:
    if args.platform:
        return args.platform
    return "windows" if platform.system() == "Windows" else "linux"


# ---------------------------------------------------------------------------
# Dry-run table
# ---------------------------------------------------------------------------


def human_size(n: float) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024:
            return f"{n:.0f}{unit}" if unit == "B" else f"{n:.1f}{unit}"
        n /= 1024
    return f"{n:.1f}TB"


def print_table() -> None:
    rows = [
        ("godot", ARTIFACTS["win64_zip"]["name"], ARTIFACTS["win64_zip"]["size"], f".tools/godot/{VERSION}/ (Windows, local)"),
        ("godot", ARTIFACTS["linux_zip"]["name"], ARTIFACTS["linux_zip"]["size"], f".tools/godot/{VERSION}/ (Linux, CI)"),
        (
            "templates",
            ARTIFACTS["templates_tpz"]["name"],
            ARTIFACTS["templates_tpz"]["size"],
            f".tools/godot/{VERSION}/editor_data/export_templates/<tpl-version>/",
        ),
        ("checksum", ARTIFACTS["sha512_sums"]["name"], ARTIFACTS["sha512_sums"]["size"], "verification source"),
        ("gut", f"{GUT_LOCAL_NAME} (tag {GUT_TAG})", GUT_ARTIFACT_SIZE, "addons/gut/ (vendored, committed)"),
        ("lint-tools", "gdtoolkit==4.5.0 (+ pip-resolved deps)", LINT_ARTIFACT_SIZE, ".tools/venv/ (from PyPI)"),
    ]
    header = f"{'Component':<12} {'File':<45} {'~Size':>8}  Destination"
    print(header)
    print("-" * len(header))
    for component, name, size, dest in rows:
        print(f"{component:<12} {name:<45} {human_size(size):>8}  {dest}")
    print()
    print(f"Base URL (Godot assets): {GODOT_RELEASE_BASE}")
    print(f"GUT source: {GUT_ZIP_URL}")
    print("gdtoolkit source: PyPI, gdtoolkit==4.5.0")


# ---------------------------------------------------------------------------
# Hashing
# ---------------------------------------------------------------------------


def _hash_file(path: Path, algo) -> str:
    h = algo()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def sha512_of_file(path: Path) -> str:
    return _hash_file(path, hashlib.sha512)


def sha256_of_file(path: Path) -> str:
    return _hash_file(path, hashlib.sha256)


# ---------------------------------------------------------------------------
# Download
# ---------------------------------------------------------------------------


def download_asset(name: str, url: str, retries: int = 3) -> Path:
    DOWNLOADS_DIR.mkdir(parents=True, exist_ok=True)
    final_path = DOWNLOADS_DIR / name
    part_path = DOWNLOADS_DIR / f"{name}.part"
    last_err: Exception | None = None
    for attempt in range(1, retries + 1):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(req) as resp, open(part_path, "wb") as f:
                shutil.copyfileobj(resp, f)
            part_path.rename(final_path)
            return final_path
        except (urllib.error.URLError, OSError) as exc:  # pragma: no cover - network dependent
            last_err = exc
            print(f"Download attempt {attempt}/{retries} failed for {name}: {exc}", file=sys.stderr)
            if part_path.exists():
                part_path.unlink()
    print(f"FATAL: could not download {name} after {retries} attempts: {last_err}", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# Checksum verification against the committed pin and/or the official file
# ---------------------------------------------------------------------------


def read_pin_file() -> dict[str, str]:
    if not PIN_FILE.exists():
        return {}
    result: dict[str, str] = {}
    for line in PIN_FILE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        parts = line.split()
        if len(parts) < 2:
            continue
        result[parts[-1]] = parts[0].lower()
    return result


def fetch_official_sums() -> dict[str, str]:
    name = ARTIFACTS["sha512_sums"]["name"]
    url = GODOT_RELEASE_BASE + name
    downloaded = download_asset(name, url)
    sums: dict[str, str] = {}
    for line in downloaded.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        parts = line.split()
        if len(parts) < 2:
            continue
        digest = parts[0].lower()
        fname = parts[-1].lstrip("*")
        sums[fname] = digest
    return sums


def get_official_sums() -> dict[str, str]:
    global _official_sums_cache
    if _official_sums_cache is None:
        _official_sums_cache = fetch_official_sums()
    return _official_sums_cache


def verify_download(filename: str, path: Path, args: argparse.Namespace) -> None:
    """Verify path's SHA512 against the pin and/or the official SHA512-SUMS.txt.

    On any mismatch, deletes the downloaded file and exits 1 with expected and
    actual hashes.
    """
    actual = sha512_of_file(path)
    pin = read_pin_file()
    expected = pin.get(filename)
    source = "committed pin (tools/godot_sha512sums.txt)" if expected else None

    if args.write_pin or expected is None:
        official = get_official_sums()
        off_hash = official.get(filename)
        if off_hash is None:
            print(f"FATAL: {filename} not present in official SHA512-SUMS.txt", file=sys.stderr)
            path.unlink(missing_ok=True)
            sys.exit(1)
        if expected is not None and off_hash != expected:
            print(f"FATAL: pin and official SHA512-SUMS.txt disagree for {filename}", file=sys.stderr)
            print(f"  pin:      {expected}")
            print(f"  official: {off_hash}")
            path.unlink(missing_ok=True)
            sys.exit(1)
        if expected is None:
            expected = off_hash
            source = "official SHA512-SUMS.txt"

    if actual != expected:
        print(f"FATAL: checksum mismatch for {filename} (source: {source})", file=sys.stderr)
        print(f"  expected: {expected}")
        print(f"  actual:   {actual}")
        path.unlink(missing_ok=True)
        sys.exit(1)
    print(f"Checksum OK for {filename} (source: {source})")


def maybe_write_pin_file(args: argparse.Namespace) -> None:
    if not args.write_pin:
        return
    official = get_official_sums()
    names = [ARTIFACTS["win64_zip"]["name"], ARTIFACTS["linux_zip"]["name"], ARTIFACTS["templates_tpz"]["name"]]
    lines = []
    for name in names:
        digest = official.get(name)
        if digest is None:
            print(f"FATAL: {name} missing from official SHA512-SUMS.txt; cannot write pin", file=sys.stderr)
            sys.exit(1)
        lines.append(f"{digest}  {name}")
    PIN_FILE.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {PIN_FILE}")


# ---------------------------------------------------------------------------
# Safe extraction (zip-slip + symlink rejection)
# ---------------------------------------------------------------------------


def _is_symlink_member(info: zipfile.ZipInfo) -> bool:
    mode = (info.external_attr >> 16) & 0xFFFF
    return stat.S_ISLNK(mode)


def safe_members(zf: zipfile.ZipFile, prefix: str | None = None):
    """Yields (info, safe_relative_path) pairs.

    Rejects any member whose normalized path is absolute or contains a `..`
    segment, and any symlink member. When `prefix` is given, only members
    under that prefix are yielded (with the prefix stripped).
    """
    for info in zf.infolist():
        name = info.filename
        if prefix is not None:
            if not name.startswith(prefix):
                continue
            rel = name[len(prefix) :]
            if rel == "":
                continue
        else:
            rel = name
        if os.path.isabs(rel):
            raise ValueError(f"zip-slip rejected (absolute path): {name}")
        norm = os.path.normpath(rel)
        if norm == ".." or norm.startswith(f"..{os.sep}") or os.path.isabs(norm):
            raise ValueError(f"zip-slip rejected (path escapes destination): {name}")
        if _is_symlink_member(info):
            raise ValueError(f"symlink member rejected: {name}")
        yield info, rel


def extract_member(zf: zipfile.ZipFile, info: zipfile.ZipInfo, rel: str, dest_dir: Path) -> None:
    target = dest_dir / rel
    if info.is_dir():
        target.mkdir(parents=True, exist_ok=True)
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    with zf.open(info) as src, open(target, "wb") as dst:
        shutil.copyfileobj(src, dst)


# ---------------------------------------------------------------------------
# Godot binary path (mirrors tools/_common.sh's duskhold_godot_bin)
# ---------------------------------------------------------------------------


def godot_bin_path(platform_name: str, dest_dir: Path | None = None) -> Path:
    dest_dir = dest_dir or (DOT_TOOLS / "godot" / VERSION)
    if platform_name == "windows":
        return dest_dir / f"Godot_v{VERSION}_win64_console.exe"
    return dest_dir / f"Godot_v{VERSION}_linux.x86_64"


# ---------------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------------


def install_godot(args: argparse.Namespace, platform_name: str) -> None:
    dest_dir = DOT_TOOLS / "godot" / VERSION
    bin_path = godot_bin_path(platform_name, dest_dir)
    if bin_path.exists() and not args.force:
        print(f"Godot already installed at {bin_path}; skipping (use --force to reinstall)")
        return

    asset = ARTIFACTS["win64_zip"] if platform_name == "windows" else ARTIFACTS["linux_zip"]
    url = GODOT_RELEASE_BASE + asset["name"]
    downloaded = download_asset(asset["name"], url)
    verify_download(asset["name"], downloaded, args)

    dest_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(downloaded) as zf:
        for info, rel in safe_members(zf):
            extract_member(zf, info, rel, dest_dir)

    if platform_name == "linux":
        exe = dest_dir / f"Godot_v{VERSION}_linux.x86_64"
        if exe.exists():
            exe.chmod(exe.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    (dest_dir / "_sc_").touch()

    if not args.keep_downloads:
        downloaded.unlink(missing_ok=True)

    print(f"Godot {VERSION} ({platform_name}) installed to {dest_dir}")


def install_templates(args: argparse.Namespace) -> None:
    templates_root = DOT_TOOLS / "godot" / VERSION / "editor_data" / "export_templates"
    if not args.force and any(templates_root.glob("*/windows_release_x86_64.exe")):
        # Skip the ~1.2 GB download when a cached/previous install already has the templates.
        print(f"Export templates already installed under {templates_root}; skipping (use --force to reinstall)")
        return

    asset = ARTIFACTS["templates_tpz"]
    url = GODOT_RELEASE_BASE + asset["name"]
    downloaded = download_asset(asset["name"], url)
    verify_download(asset["name"], downloaded, args)

    with zipfile.ZipFile(downloaded) as zf:
        try:
            with zf.open("templates/version.txt") as f:
                tpl_version = f.read().decode("utf-8").strip()
        except KeyError:
            print("FATAL: templates/version.txt not found in export templates archive", file=sys.stderr)
            sys.exit(1)

        dest_dir = DOT_TOOLS / "godot" / VERSION / "editor_data" / "export_templates" / tpl_version
        dest_dir.mkdir(parents=True, exist_ok=True)

        for info in zf.infolist():
            name = info.filename
            if name == "templates/version.txt":
                rel = "version.txt"
            elif name.startswith("templates/windows_"):
                rel = name[len("templates/") :]
            else:
                continue
            if os.path.isabs(rel):
                raise ValueError(f"zip-slip rejected (absolute path): {name}")
            norm = os.path.normpath(rel)
            if norm == ".." or norm.startswith(f"..{os.sep}"):
                raise ValueError(f"zip-slip rejected (path escapes destination): {name}")
            if _is_symlink_member(info):
                raise ValueError(f"symlink member rejected: {name}")
            if info.is_dir():
                continue
            target = dest_dir / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            with zf.open(info) as src, open(target, "wb") as dst:
                shutil.copyfileobj(src, dst)

    if not args.keep_downloads:
        downloaded.unlink(missing_ok=True)

    print(f"Export templates ({tpl_version}) extracted to {dest_dir}")


def install_gut(args: argparse.Namespace) -> str:
    dest_dir = ROOT / "addons" / "gut"
    if dest_dir.exists() and not args.force:
        print("FATAL: addons/gut already exists; use --force to overwrite", file=sys.stderr)
        sys.exit(1)

    downloaded = download_asset(GUT_LOCAL_NAME, GUT_ZIP_URL)
    sha256 = sha256_of_file(downloaded)
    print(f"GUT {GUT_TAG} zip SHA256: {sha256}")

    prefix = None
    with zipfile.ZipFile(downloaded) as zf:
        for info in zf.infolist():
            idx = info.filename.find("addons/gut/")
            if idx != -1:
                prefix = info.filename[: idx + len("addons/gut/")]
                break
        if prefix is None:
            print("FATAL: addons/gut/ not found in GUT archive", file=sys.stderr)
            sys.exit(1)

        if dest_dir.exists():
            shutil.rmtree(dest_dir)
        for info, rel in safe_members(zf, prefix=prefix):
            extract_member(zf, info, rel, dest_dir)

    plugin_cfg = dest_dir / "plugin.cfg"
    if not plugin_cfg.exists() or "9.7.1" not in plugin_cfg.read_text(encoding="utf-8"):
        print("FATAL: addons/gut/plugin.cfg does not report version 9.7.1", file=sys.stderr)
        sys.exit(1)

    if not args.keep_downloads:
        downloaded.unlink(missing_ok=True)

    print(f"GUT {GUT_TAG} vendored to {dest_dir}")
    return sha256


def install_lint_tools(args: argparse.Namespace) -> None:
    venv_dir = DOT_TOOLS / "venv"
    if not venv_dir.exists():
        subprocess.run([sys.executable, "-m", "venv", str(venv_dir)], check=True)

    if platform.system() == "Windows":
        pip_path = venv_dir / "Scripts" / "pip.exe"
        gdlint_path = venv_dir / "Scripts" / "gdlint.exe"
    else:
        pip_path = venv_dir / "bin" / "pip"
        gdlint_path = venv_dir / "bin" / "gdlint"

    subprocess.run([str(pip_path), "install", "-r", str(REQUIREMENTS_LINT_FILE)], check=True)
    result = subprocess.run([str(gdlint_path), "--version"], check=True, capture_output=True, text=True)
    print(result.stdout.strip() or result.stderr.strip())


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    plat = resolve_platform(args)

    if args.print_godot_path:
        print(godot_bin_path(plat))
        return 0

    if args.all:
        args.godot = True
        args.templates = True
        args.gut = True
        args.lint_tools = True

    selected = args.godot or args.templates or args.gut or args.lint_tools

    if args.dry_run or not selected:
        print_table()
        return 0

    if not args.yes:
        print_table()
        print()
        print("Downloads require --yes (owner approval)")
        return 2

    # Everything from here on may touch the network.
    if args.godot:
        install_godot(args, plat)
    if args.templates:
        install_templates(args)
    if args.write_pin:
        maybe_write_pin_file(args)
    if args.gut:
        install_gut(args)
    if args.lint_tools:
        install_lint_tools(args)

    return 0


if __name__ == "__main__":
    sys.exit(main())
