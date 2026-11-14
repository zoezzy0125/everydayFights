#!/usr/bin/env python3
"""One-time local import from a read-only Apple Reminders JSON snapshot.
Stop everydayFights before invoking. This script never contacts Apple Reminders.
Existing imported IDs are skipped, not overwritten. No ongoing sync is installed.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import shutil
import tempfile
import uuid

parser = argparse.ArgumentParser()
parser.add_argument('snapshot', type=Path)
parser.add_argument('--destination', type=Path, required=True)
args = parser.parse_args()
source = json.loads(args.snapshot.read_text())
items = [(group, item) for group in source for item in group['reminders']]
ids = [item['id'] for _, item in items]
assert len(ids) == len(set(ids)), 'Duplicate source IDs; import aborted'
assert all(item.get('containerId') == group['id'] for group, item in items), 'Nested or unknown parent relationships require explicit mapping; import aborted'
assert all('containerReadError' not in item for _, item in items), 'Source hierarchy read failed'
dest = args.destination
assert dest.exists(), 'Create or explicitly prepare a destination snapshot first'
state = json.loads(dest.read_text())
assert state['version'] == 1
existing = {t.get('sourceReminderID') for t in state['tasks']}
epoch = datetime(2001, 1, 1, tzinfo=timezone.utc)
def swift_date(value):
    return (datetime.fromisoformat(value.replace('Z', '+00:00')) - epoch).total_seconds() if value else None
added = []
for group, item in items:
    if item['id'] in existing:
        continue
    notes = item.get('body') or ''
    # Classification is derived solely from the user's data marker and confirmed migration rule.
    kind = 'daily' if 'EdgeTodo-Section: daily' in notes.splitlines() else 'goal'
    task = dict(id=str(uuid.uuid5(uuid.NAMESPACE_URL, item['id'])).upper(), title=item['name'], emoji='', kind=kind,
                dueDate=swift_date(item.get('dueDate')), includesTime=bool(item.get('dueDate') and item.get('dueDate') != item.get('alldayDueDate')),
                isComplete=item['completed'], checklist=[], sourceReminderID=item['id'], sourceNotes=notes, sourceList=group['name'])
    # Preserve title exactly, including any emoji embedded by the source. Do not invent metadata.
    state['tasks'].append(task)
    added.append(task)
if added:
    backup_dir = dest.parent / 'migration'
    backup_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
    digest = hashlib.sha256(dest.read_bytes()).hexdigest()[:12]
    backup = backup_dir / ('before-import-' + digest + '.json')
    if not backup.exists():
        shutil.copy2(dest, backup)
        backup.chmod(0o600)
    with tempfile.NamedTemporaryFile('w', dir=dest.parent, delete=False) as f:
        json.dump(state, f, ensure_ascii=False, indent=2)
        temp = Path(f.name)
    temp.chmod(0o600)
    temp.replace(dest)
print(json.dumps({'source_count': len(items), 'added': len(added), 'skipped_existing': len(items)-len(added), 'destination_count': len(state['tasks'])}))
