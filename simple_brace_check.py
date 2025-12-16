# -*- coding: utf-8 -*-
import sys

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

# Find struct Index
struct_start = None
for i, line in enumerate(lines):
    if 'struct Index {' in line:
        struct_start = i
        break

print(f"struct Index starts at line {struct_start + 1}", file=sys.stderr)

# Track braces
brace_count = 0
for i in range(struct_start, len(lines)):
    for char in lines[i]:
        if char == '{':
            brace_count += 1
        elif char == '}':
            brace_count -= 1
    
    if brace_count == 0 and i > struct_start:
        print(f"struct Index ends at line {i + 1}", file=sys.stderr)
        print(f"Lines in struct: {i - struct_start + 1}", file=sys.stderr)
        print(f"Lines after struct: {len(lines) - i - 1}", file=sys.stderr)
        
        # Show lines after struct
        if len(lines) - i - 1 > 5:
            print(f"\nFirst 10 lines after struct end:", file=sys.stderr)
            for j in range(i+1, min(i+11, len(lines))):
                print(f"  {j+1}: {lines[j].rstrip()[:70]}", file=sys.stderr)
        break
else:
    print(f"ERROR: struct never closes! Final count: {brace_count}", file=sys.stderr)

# Find build()
for i in range(struct_start, len(lines)):
    if 'build()' in lines[i] and '{' in lines[i]:
        # Calculate depth
        depth = 0
        for j in range(struct_start, i+1):
            for char in lines[j]:
                if char == '{':
                    depth += 1
                elif char == '}':
                    depth -= 1
        print(f"\nbuild() at line {i+1}, depth={depth}", file=sys.stderr)
        if depth != 2:
            print(f"WARNING: build() depth should be 2, but is {depth}!", file=sys.stderr)
        break

