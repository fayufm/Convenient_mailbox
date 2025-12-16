# -*- coding: utf-8 -*-
"""移除updateUITexts方法的try-catch包装，简化结构"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print("查找updateUITexts方法...")

# Find updateUITexts method
method_start = None
for i, line in enumerate(lines):
    if 'updateUITexts(language: string) {' in line:
        method_start = i
        print(f"Found at line {i+1}")
        break

# Find the try line (should be a few lines after method start)
try_line = None
for i in range(method_start, min(method_start + 10, len(lines))):
    if 'try {' in lines[i]:
        try_line = i
        print(f"Found try at line {i+1}")
        break

# Find the catch block (around line 6566)
catch_line = None
for i in range(try_line + 100, min(try_line + 2000, len(lines))):
    if '} catch (error) {' in lines[i]:
        catch_line = i
        print(f"Found catch at line {i+1}")
        break

if not all([method_start, try_line, catch_line]):
    print("ERROR: Could not find all required lines!")
    exit(1)

print(f"\nRemoving try-catch wrapper...")

# Strategy:
# 1. Remove the "try {" line
# 2. Remove the "} catch (error) { ... }" block

# Remove try line
del lines[try_line]
print(f"  Removed try at line {try_line+1}")

# catch_line index is now shifted by -1
catch_line -= 1

# Find the end of catch block
catch_end = None
for i in range(catch_line, min(catch_line + 10, len(lines))):
    # Look for the closing brace of catch block
    if lines[i].strip() == '}':
        # This should be the end of catch
        catch_end = i
        break

if not catch_end:
    # Try to find it more carefully
    brace_count = 0
    for i in range(catch_line, min(catch_line + 20, len(lines))):
        for char in lines[i]:
            if char == '{':
                brace_count += 1
            elif char == '}':
                brace_count -= 1
        if brace_count == -1:  # Catch block closed
            catch_end = i
            break

if catch_end:
    # Remove catch block (from "} catch" to closing "}")
    num_lines = catch_end - catch_line + 1
    del lines[catch_line:catch_end+1]
    print(f"  Removed catch block at lines {catch_line+1} to {catch_end+1} ({num_lines} lines)")
else:
    print("  WARNING: Could not find catch block end!")

# Write back
with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8', errors='ignore') as f:
    f.writelines(lines)

print(f"\n✅ 完成！updateUITexts方法已简化")
print(f"   总行数: {len(lines)}")

# Show the result
print(f"\n验证 - 方法开始部分:")
for i in range(method_start, min(method_start + 10, len(lines))):
    print(f"  {i+1}: {lines[i].rstrip()[:70]}")

