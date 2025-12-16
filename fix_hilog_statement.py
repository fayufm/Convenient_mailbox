# -*- coding: utf-8 -*-
"""修复hilog.info语句和updateUITexts方法的结束花括号"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print("修复hilog.info语句...")

# Find the problematic lines (around 6565-6569)
for i in range(6564, min(6570, len(lines))):
    print(f"{i+1}: {repr(lines[i][:80])}")

# Fix:
# Line 6567 should be deleted (the misplaced })
# Line 6568 should be properly indented
# A new closing brace should be added after line 6568

if 6566 < len(lines) and '  }' in lines[6566]:
    print(f"\nRemoving misplaced }} at line {6567}")
    lines.pop(6566)  # Remove line 6567

# Now line 6567 is what was line 6568 (the second part of hilog.info)
# Fix its indentation
if 6566 < len(lines):
    lines[6566] = "      'UI湰叉洿负: %{public}s', language)\n"
    print(f"Fixed line {6567} indentation")

# Add closing brace for updateUITexts method after the hilog.info statement
lines.insert(6567, "  }\n")
print(f"Added closing brace at line {6568}")

# Write back
with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8', errors='ignore') as f:
    f.writelines(lines)

print(f"\n✅ 完成！修复后的代码:")
for i in range(6564, min(6572, len(lines))):
    print(f"{i+1}: {lines[i].rstrip()[:80]}")

