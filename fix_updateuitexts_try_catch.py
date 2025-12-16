# -*- coding: utf-8 -*-
"""为updateUITexts方法添加缺失的catch块"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

# Find where the try block ends (line 6514 based on previous analysis)
# The try block closes at line 6514, so we need to add catch after the closing }

# Actually, we need to find the actual line number
try_found = False
brace_count = 0

for i, line in enumerate(lines):
    if 'updateUITexts(language: string) {' in line:
        updateuitexts_start = i
        try_found = False
        continue
        
    if try_found and (i - updateuitexts_start) < 2000:
        # Count braces after try
        for char in line:
            if char == '{':
                brace_count += 1
            elif char == '}':
                brace_count -= 1
                
        # When brace count returns to 0, the try block has ended
        if brace_count == 0 and i > updateuitexts_start + 10:
            print(f"try block ends at line {i + 1}")
            print(f"  Line content: {line.strip()[:60]}")
            
            # Insert catch block after this line
            # The line after should be the hilog.info statement (line 6566-6567)
            # We need to insert before that
            
            # But first check what's on the next lines
            print(f"\nNext 5 lines after try block:")
            for j in range(i, min(i + 5, len(lines))):
                print(f"  {j + 1}: {lines[j].rstrip()[:70]}")
            
            # Insert catch block
            catch_block = [
                "    } catch (error) {\n",
                "      const err = error as Error\n",
                "      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,\n",
                "        'updateUITexts error: %{public}s', err.message)\n"
            ]
            
            # Insert at position i+1 (after the closing } of try block)
            for idx, catch_line in enumerate(catch_block):
                lines.insert(i + 1 + idx, catch_line)
            
            print(f"\n✅ Added catch block at line {i + 2}")
            print(f"\nResult:")
            for j in range(i, min(i + 10, len(lines) + len(catch_block))):
                print(f"  {j + 1}: {lines[j].rstrip()[:70]}")
            
            break
            
    if 'try {' in line and (i - updateuitexts_start if 'updateuitexts_start' in locals() else 999) < 10:
        try_found = True
        brace_count = 0
        print(f"Found try at line {i + 1}")

# Write back
with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8', errors='ignore') as f:
    f.writelines(lines)

print(f"\n✅ 完成！已添加catch块到updateUITexts方法")

