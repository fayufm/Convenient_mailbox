# -*- coding: utf-8 -*-
"""找到try块内的多余closing brace"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

try_start = 5103  # Line 5104
obj_end = 6564  # Line 6565

print("Tracking brace balance line by line...")
print("Lines where balance goes negative:\n")

brace_count = 0
negative_lines = []

for i in range(try_start, obj_end + 1):
    line = lines[i]
    prev_count = brace_count
    
    for char in line:
        if char == '{':
            brace_count += 1
        elif char == '}':
            brace_count -= 1
    
    # If balance went negative or changed significantly
    if brace_count < 0 or (prev_count >= 0 and brace_count < 0):
        negative_lines.append((i+1, brace_count, lines[i].rstrip()))
    
    # Report lines with large negative counts
    if brace_count < -5:
        print(f"  Line {i+1}: count={brace_count:+3d}  {lines[i].rstrip()[:60]}")

print(f"\nFirst 10 lines where balance became or stayed negative:")
for line_num, count, content in negative_lines[:10]:
    print(f"  Line {line_num}: count={count:+3d}  {content[:70]}")

print(f"\n\nSearching for suspicious patterns...")

# Look for common error patterns
for i in range(try_start, obj_end + 1):
    line = lines[i].strip()
    
    # Double closing braces
    if '}}'  in line:
        print(f"  Line {i+1} has }}: {line[:70]}")
    
    # Closing brace at start of line (might be misplaced)
    if line.startswith('}') and i > try_start + 10:
        # Count how many { and } in previous 3 lines
        prev_opens = sum([lines[j].count('{') for j in range(max(try_start, i-3), i)])
        prev_closes = sum([lines[j].count('}') for j in range(max(try_start, i-3), i)])
        if prev_opens <= prev_closes:
            print(f"  Line {i+1} suspicious lone }}: prev 3 lines: opens={prev_opens}, closes={prev_closes}")
            print(f"    {lines[i].rstrip()[:70]}")

