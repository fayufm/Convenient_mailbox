# -*- coding: utf-8 -*-
"""全面分析Index.ets的花括号平衡"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print("="*80)
print("花括号平衡分析")
print("="*80)

# Find struct Index
struct_start = None
for i, line in enumerate(lines):
    if 'struct Index {' in line:
        struct_start = i
        break

if not struct_start:
    print("ERROR: struct Index not found!")
    exit(1)

print(f"\nstruct Index starts at line {struct_start + 1}")

# Track brace balance from struct start
brace_count = 0
max_depth = 0
min_depth = 0
issues = []

for i in range(struct_start, len(lines)):
    line = lines[i]
    line_brace_change = 0
    
    for char in line:
        if char == '{':
            brace_count += 1
            line_brace_change += 1
            max_depth = max(max_depth, brace_count)
        elif char == '}':
            brace_count -= 1
            line_brace_change -= 1
            min_depth = min(min_depth, brace_count)
    
    # Check for issues
    if brace_count < 0:
        issues.append((i+1, brace_count, "Negative brace count!", line.strip()[:60]))
    
    # Record lines with significant changes
    if abs(line_brace_change) > 0 and (i-struct_start) < 50:  # First 50 lines
        print(f"  Line {i+1}: balance={brace_count:+3d} change={line_brace_change:+2d}  {line.strip()[:60]}")
    
    # Check if struct ends (brace_count returns to 0)
    if brace_count == 0 and i > struct_start:
        print(f"\n✅ struct Index ends properly at line {i+1}")
        print(f"   Max nesting depth: {max_depth}")
        print(f"   Lines in struct: {i - struct_start + 1}")
        print(f"   Lines after struct end: {len(lines) - i - 1}")
        
        # Check if there's significant code after struct
        if len(lines) - i - 1 > 10:
            print(f"\n⚠️  WARNING: There are {len(lines) - i - 1} lines after struct Index closes!")
            print(f"   This code will NOT be part of struct Index!")
            print(f"\n   Lines {i+2} to {i+12}:")
            for j in range(i+1, min(i+11, len(lines))):
                print(f"      {j+1}: {lines[j].rstrip()[:70]}")
        break
else:
    # Loop completed without break - struct never closed
    print(f"\n❌ ERROR: struct Index never closes!")
    print(f"   Final brace count: {brace_count}")
    print(f"   This means {brace_count} unclosed {{")

if issues:
    print(f"\n❌ Found {len(issues)} brace balance issues:")
    for line_num, count, msg, content in issues[:10]:
        print(f"   Line {line_num}: {msg} (count={count}) {content}")

# Find build() method
print(f"\n" + "="*80)
print("build() 方法位置分析")
print("="*80)

build_line = None
for i, line in enumerate(lines):
    if i > struct_start and 'build()' in line and '{' in line:
        build_line = i
        # Calculate brace count at this point from struct start
        temp_count = 0
        for j in range(struct_start, i+1):
            for char in lines[j]:
                if char == '{':
                    temp_count += 1
                elif char == '}':
                    temp_count -= 1
        
        print(f"build() method at line {i+1}")
        print(f"  Brace depth at this line: {temp_count}")
        print(f"  Expected depth: 2 (struct body = 1, method body starts = 2)")
        
        if temp_count != 2:
            print(f"  ⚠️  WARNING: Unexpected depth! Should be 2, but is {temp_count}")
            print(f"     This suggests syntax errors before build() method")
        break

if not build_line:
    # Try finding build() without {
    for i, line in enumerate(lines):
        if i > struct_start and re.search(r'\s*build\s*\(\s*\)', line):
            build_line = i
            print(f"build() method at line {i+1} (opening brace on next line?)")
            break

print("\n" + "="*80)

