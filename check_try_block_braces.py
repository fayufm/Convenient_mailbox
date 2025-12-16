# -*- coding: utf-8 -*-
"""检查try块内部的花括号平衡"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

# Line 5104 is where try { starts
# Line 6565 is where object literal ends
# Line 6566 is } catch (error) {

try_start = 5103  # 0-indexed, so line 5104
obj_end = 6564  # Line 6565
catch_line = 6565  # Line 6566

print(f"Analyzing lines {try_start+1} to {catch_line+1}...")

# Count braces from try start
brace_count = 0
for i in range(try_start, catch_line + 1):
    line = lines[i]
    for char in line:
        if char == '{':
            brace_count += 1
        elif char == '}':
            brace_count -= 1
    
    # Report significant lines
    if i == try_start:
        print(f"  Line {i+1} (try {{): count={brace_count}")
    elif i == obj_end:
        print(f"  Line {i+1} (object end): count={brace_count}")
    elif i == catch_line:
        print(f"  Line {i+1} (}} catch): count before line={brace_count}")
        # The } catch line will have } (close try) and { (open catch)
        # So net change is 0, but we want to know state before processing this line
        temp_count = brace_count
        # Recalculate without this line
        for char in lines[i]:
            if char == '{':
                temp_count -= 1
            elif char == '}':
                temp_count += 1
        print(f"    Brace count BEFORE this line processes: {temp_count}")
        print(f"    This line content: {lines[i].strip()}")

print(f"\nFinal brace count after line {catch_line+1}: {brace_count}")

if brace_count == 1:
    print("  OK: try block properly closed, catch block opened")
elif brace_count == 0:
    print("  ERROR: Both try and catch are closed!")
elif brace_count > 1:
    print(f"  ERROR: try block NOT closed! Missing {brace_count-1} closing braces")
else:
    print(f"  ERROR: Too many closing braces!")

# Check the actual line
print(f"\nLine {catch_line+1} content:")
print(f"  {lines[catch_line]}")

# Count { and } separately in this line
open_count = lines[catch_line].count('{')
close_count = lines[catch_line].count('}')
print(f"  Opens: {open_count}, Closes: {close_count}")

