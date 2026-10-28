#!/usr/bin/env python3
"""Create the agent's workspace folders and keep them indexed in memory/index.md.

    workspace.py init                                   brand/, memory/, jobs/ + memory/index.md and misc.md
    workspace.py job SLUG [--title "…"]                 jobs/<date>-<slug>/{src,work,out} + brief.md, indexed under Jobs
    workspace.py status JOB STATUS [--link URL]         update a job's status (started, draft, approved, delivered…)
    workspace.py folder PATH "description"              create any other folder and list it under Workspace
    workspace.py note SLUG "summary" [--applies-to X]   memory/important/<date>-<slug>.md, indexed under Important notes
    workspace.py list                                   print the indexed jobs

Paths are relative to the project root (git top level, or the current directory). Every command
runs `init` first, so folders are always created on demand. Uses only the standard library.
"""
import argparse
import datetime as dt
import os
import re
import subprocess
import sys
import unicodedata
from pathlib import Path

SKILL_DIR = Path(__file__).resolve().parent.parent
TODAY = dt.date.today().isoformat()

# Written into every memory index, so the agent always routes video requests through the skill.
STANDING_RULE = (
    "- **Video requests → `video-editor` skill.** Whenever the user asks to edit, cut, caption, animate, render, "
    "export or deliver a video, load the `video-editor` skill (`SKILL.md`) first and follow it. Set at install; don't remove."
)

FOLDERS = [
    "brand/assets/logo",
    "brand/assets/fonts",
    "brand/assets/music",
    "memory/important",
    "jobs",
]


def project_root():
    if os.environ.get("PROJECT_ROOT"):
        return Path(os.environ["PROJECT_ROOT"]).resolve()
    try:
        out = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True)
        return Path(out.stdout.strip())
    except (OSError, subprocess.CalledProcessError):
        return Path.cwd()


ROOT = project_root()
INDEX = ROOT / "memory" / "index.md"


def slugify(text):
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    s = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return s or "untitled"


def rel(path):
    return os.path.relpath(path, ROOT)


# ------------------------------------------------------------------ index editing

def read_index():
    return INDEX.read_text(encoding="utf-8").splitlines()


def write_index(lines):
    INDEX.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def section_bounds(lines, heading):
    """Return (start, end) line indexes of a '## heading' section body, or None."""
    for i, line in enumerate(lines):
        if line.strip() == f"## {heading}":
            end = next((j for j in range(i + 1, len(lines)) if lines[j].startswith("## ")), len(lines))
            return i + 1, end
    return None


def ensure_section(lines, heading, body, before="## Proven pipelines"):
    if section_bounds(lines, heading):
        return lines
    at = next((i for i, l in enumerate(lines) if l.strip() == before), len(lines))
    return lines[:at] + [f"## {heading}", "", *body, ""] + lines[at:]


def add_bullet(heading, line, key=None):
    """Add (or replace, when a bullet containing `key` exists) a bullet in a section."""
    lines = read_index()
    start, end = section_bounds(lines, heading)
    body = lines[start:end]
    if key:
        for i, l in enumerate(body):
            if l.startswith("- ") and key in l:
                body[i] = line
                break
        else:
            body = _append(body, line)
    else:
        body = _append(body, line)
    write_index(lines[:start] + body + lines[end:])


def _append(body, line):
    body = [l for l in body if not l.startswith("- _")]  # drop "None yet" placeholders
    while body and not body[-1].strip():
        body.pop()
    if not body or not body[0].strip() == "":
        body.insert(0, "")
    return body + [line, ""]


def add_table_row(heading, row, key):
    lines = read_index()
    start, end = section_bounds(lines, heading)
    rows = [i for i in range(start, end) if lines[i].startswith("|")]
    for i in rows:
        if key in lines[i]:
            lines[i] = row
            break
    else:
        at = rows[-1] + 1 if rows else start
        lines.insert(at, row)
    write_index(lines)


# ------------------------------------------------------------------ commands

def cmd_init(quiet=False):
    created = []
    for f in FOLDERS:
        p = ROOT / f
        if not p.exists():
            p.mkdir(parents=True)
            created.append(f + "/")
    if not INDEX.exists():
        template = (SKILL_DIR / "templates" / "memory-index.md").read_text(encoding="utf-8")
        INDEX.write_text(template.replace("{{DATE}}", TODAY), encoding="utf-8")
        created.append("memory/index.md")
    else:
        # Older indexes: add the sections this script maintains.
        lines = read_index()
        lines = ensure_section(lines, "Standing rules", [STANDING_RULE], before="## Setup status")
        lines = ensure_section(lines, "Workspace", [
            "| Folder | Contents |", "| --- | --- |",
            "| [`brand/`](../brand/) | Brand profile ([profile.md](../brand/profile.md)) and `assets/` |",
            "| [`memory/important/`](important/) | Dated notes on decisions and corrections |",
            "| [`jobs/`](../jobs/) | One folder per job: `src/`, `work/`, `out/` |",
        ])
        lines = ensure_section(lines, "Jobs", [])
        lines = ensure_section(lines, "Important notes", [], before="## Misc")
        write_index(lines)
    misc = ROOT / "memory" / "misc.md"
    if not misc.exists():
        misc.write_text("# Misc findings\n\nSmall findings, one bullet each, newest last.\n", encoding="utf-8")
        created.append("memory/misc.md")
    if not quiet:
        print("workspace: created " + ", ".join(created) if created else "workspace: already initialized")
        print(f"workspace: root {ROOT}")


def find_job(name):
    jobs = ROOT / "jobs"
    exact = jobs / name
    if exact.is_dir():
        return exact
    matches = sorted(p for p in jobs.iterdir() if p.is_dir() and (p.name.endswith("-" + name) or name in p.name))
    if len(matches) == 1:
        return matches[0]
    if not matches:
        sys.exit(f"workspace: no job matching '{name}'")
    sys.exit("workspace: ambiguous job name; matches: " + ", ".join(p.name for p in matches))


def job_line(job, title, status, link=None):
    line = f"- [{job.name}](../jobs/{job.name}/) — {title} · status: {status} · updated {TODAY}"
    return line + (f" · [delivery]({link})" if link else "")


def cmd_job(args):
    cmd_init(quiet=True)
    date = args.date or TODAY
    job = ROOT / "jobs" / f"{date}-{slugify(args.slug)}"
    existed = job.exists()
    for sub in ("src", "work", "out"):
        (job / sub).mkdir(parents=True, exist_ok=True)
    title = args.title or args.slug.replace("-", " ")
    brief = job / "brief.md"
    if not brief.exists():
        brief.write_text(
            f"# {title}\n\n"
            f"- **Job:** {job.name}\n- **Created:** {TODAY}\n- **Status:** started\n"
            f"- **Format:** TBD\n- **Deliverables:** TBD\n\n"
            "## Brief\n\nTBD — what the user asked for, audience, length, CTA.\n\n"
            "## Log\n\n"
            f"- {TODAY}: job created.\n",
            encoding="utf-8",
        )
    add_bullet("Jobs", job_line(job, title, "started"), key=f"[{job.name}]")
    print(f"workspace: {'reused' if existed else 'created'} {rel(job)}/{{src,work,out}} and indexed it")
    print(rel(job))


def cmd_status(args):
    cmd_init(quiet=True)
    job = find_job(args.job)
    brief = job / "brief.md"
    title = job.name
    if brief.exists():
        text = brief.read_text(encoding="utf-8")
        m = re.match(r"# (.+)", text)
        title = m.group(1) if m else title
        text = re.sub(r"- \*\*Status:\*\* .*", f"- **Status:** {args.status}", text, count=1)
        note = f"- {TODAY}: status → {args.status}" + (f" ({args.link})" if args.link else "") + "\n"
        brief.write_text(text.rstrip("\n") + "\n" + note, encoding="utf-8")
    add_bullet("Jobs", job_line(job, title, args.status, args.link), key=f"[{job.name}]")
    print(f"workspace: {job.name} → {args.status}")


def cmd_folder(args):
    cmd_init(quiet=True)
    path = (ROOT / args.path).resolve()
    if ROOT not in path.parents and path != ROOT:
        sys.exit("workspace: folders must be inside the project root")
    path.mkdir(parents=True, exist_ok=True)
    r = rel(path)
    add_table_row("Workspace", f"| [`{r}/`](../{r}/) | {args.description} |", key=f"[`{r}/`]")
    print(f"workspace: {r}/ ready and indexed")


def cmd_note(args):
    cmd_init(quiet=True)
    name = f"{TODAY}-{slugify(args.slug)}"
    path = ROOT / "memory" / "important" / f"{name}.md"
    if not path.exists():
        path.write_text(
            f"# {args.summary}\n\n"
            f"- **Date:** {TODAY}\n- **Job:** {args.job or 'n/a'}\n"
            "- **What happened:** TBD\n- **Correction / better approach:** TBD\n"
            f"- **Applies to:** {args.applies_to or 'all jobs'}\n",
            encoding="utf-8",
        )
    add_bullet("Important notes", f"- [{name}](important/{name}.md) — {args.summary}", key=f"[{name}]")
    print(f"workspace: {rel(path)} indexed — fill in its TBD fields")
    print(rel(path))


def cmd_list(_):
    cmd_init(quiet=True)
    lines = read_index()
    start, end = section_bounds(lines, "Jobs")
    jobs = [l for l in lines[start:end] if l.startswith("- ")]
    print("\n".join(jobs) if jobs else "workspace: no jobs yet")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("init")
    p = sub.add_parser("job"); p.add_argument("slug"); p.add_argument("--title"); p.add_argument("--date")
    p = sub.add_parser("status"); p.add_argument("job"); p.add_argument("status"); p.add_argument("--link")
    p = sub.add_parser("folder"); p.add_argument("path"); p.add_argument("description")
    p = sub.add_parser("note"); p.add_argument("slug"); p.add_argument("summary")
    p.add_argument("--applies-to"); p.add_argument("--job")
    sub.add_parser("list")
    args = ap.parse_args()
    {"init": lambda a: cmd_init(), "job": cmd_job, "status": cmd_status, "folder": cmd_folder,
     "note": cmd_note, "list": cmd_list}[args.cmd](args)


if __name__ == "__main__":
    main()
