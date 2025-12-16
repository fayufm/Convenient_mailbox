# -*- coding: utf-8 -*-
"""修复updateUITexts方法缺少结束花括号的问题"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print("查找updateUITexts方法...")

# Find updateUITexts method start
updateuitexts_start = None
for i, line in enumerate(lines):
    if 'updateUITexts(language: string)' in line:
        updateuitexts_start = i
        print(f"Found updateUITexts at line {i+1}")
        break

if not updateuitexts_start:
    print("ERROR: updateUITexts method not found!")
    exit(1)

# Find where the object literal ends (line 6565)
obj_end = None
for i in range(updateuitexts_start, len(lines)):
    if "'featureDescription':" in lines[i] and lines[i].strip().endswith('}'):
        obj_end = i
        print(f"Object literal ends at line {i+1}: {lines[i].strip()[:60]}")
        break

if not obj_end:
    print("ERROR: Could not find object literal end!")
    exit(1)

# Check what's on the next few lines
print(f"\nLines after object literal end:")
for i in range(obj_end, min(obj_end + 10, len(lines))):
    print(f"  {i+1}: {lines[i].rstrip()[:80]}")

# The fix: add closing brace for the method after the hilog.info statement
print(f"\n修复方案:")
print(f"在line {obj_end+1} (hilog.info...) 添加一个结束花括号")

# Find if there's already code after hilog.info
hilog_end = obj_end + 2  # Line after hilog.info statement

# Insert closing brace for updateUITexts method
print(f"\n执行修复...")
lines.insert(hilog_end, "  }\n")  # Close updateUITexts method

# Write back
with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8', errors='ignore') as f:
    f.writelines(lines)

print(f"✅ 完成！在line {hilog_end+1}添加了结束花括号")
print(f"\n修复后的代码:")
for i in range(obj_end, min(obj_end + 8, len(lines))):
    marker = ">>> " if i == hilog_end else "    "
    print(f"{marker}{i+1}: {lines[i].rstrip()[:80]}")

