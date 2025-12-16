# -*- coding: utf-8 -*-
"""查找updateUITexts方法中的try-catch块"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

# Find updateUITexts method
updateuitexts_start = None
for i, line in enumerate(lines):
    if 'updateUITexts(language: string) {' in line:
        updateuitexts_start = i
        break

if not updateuitexts_start:
    print("ERROR: updateUITexts not found!")
    exit(1)

print(f"updateUITexts starts at line {updateuitexts_start + 1}")

# Find the try block
try_line = None
for i in range(updateuitexts_start, min(updateuitexts_start + 10, len(lines))):
    if 'try {' in lines[i]:
        try_line = i
        print(f"try block at line {i + 1}")
        break

if not try_line:
    print("No try block found in first 10 lines")
    exit(1)

# Look for corresponding catch block
# Track brace count from try
brace_count = 0
found_try_open = False
catch_line = None

for i in range(try_line, min(try_line + 2000, len(lines))):
    line = lines[i]
    
    # Count braces
    for char in line:
        if char == '{':
            brace_count += 1
            if i == try_line:
                found_try_open = True
        elif char == '}':
            brace_count -= 1
            
    # Check for catch
    if '} catch' in line or '}catch' in line:
        catch_line = i
        print(f"\nFound catch at line {i + 1}:")
        print(f"  {line.strip()}")
        break
    
    # If we hit the next method before finding catch, report
    if i > try_line + 5 and brace_count == 0:
        print(f"\n❌ ERROR: try block closed at line {i + 1} but NO catch block found!")
        print(f"   This is INVALID syntax - try must have catch or finally")
        print(f"\n   Line {i + 1}: {lines[i].strip()[:70]}")
        print(f"\n   Next few lines:")
        for j in range(i, min(i + 5, len(lines))):
            print(f"      {j + 1}: {lines[j].rstrip()[:70]}")
        break

if not catch_line and brace_count > 0:
    print(f"\n⚠️  WARNING: try block still open at end of search")
    print(f"   Brace count: {brace_count}")

