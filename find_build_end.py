# -*- coding: utf-8 -*-
"""查找Index.ets中build()方法的结束位置"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

# Find build() method start
build_start = None
for i, line in enumerate(lines, 1):
    if 'build()' in line and '{' in line:
        build_start = i
        print(f"Found build() at line {i}")
        break
    elif i == 981:  # We know it's around here
        if 'build()' in line:
            build_start = i
            print(f"Found build() at line {i}")
            # Check next line for {
            if i < len(lines) and '{' not in line:
                print(f"  Opening {{ might be on next line")
            break

if not build_start:
    print("ERROR: build() method not found!")
    exit(1)

# Find matching closing brace
brace_count = 0
in_build = False
build_end = None

for i in range(build_start - 1, len(lines)):
    line = lines[i]
    
    # Count braces
    for char in line:
        if char == '{':
            brace_count += 1
            in_build = True
        elif char == '}':
            brace_count -= 1
            
            if in_build and brace_count == 0:
                build_end = i + 1
                print(f"\nFound build() end at line {build_end}")
                print(f"build() method spans {build_end - build_start + 1} lines")
                break
    
    if build_end:
        break

if not build_end:
    print(f"\nWARNING: Could not find closing brace for build() method!")
    print(f"Brace count at end of file: {brace_count}")
    print(f"This means the build() method is not properly closed!")
else:
    # Check if there's anything after build() method before struct end
    remaining_lines = len(lines) - build_end
    print(f"\nLines after build() method: {remaining_lines}")
    
    # Check if there are any other method-like patterns
    print(f"\nChecking for other methods after build()...")
    method_pattern_count = 0
    for i in range(build_end, len(lines)):
        line = lines[i].strip()
        # Look for method-like patterns: word followed by (
        if line and not line.startswith('//') and not line.startswith('/*'):
            import re
            if re.match(r'^\w+\s*\(', line) or re.match(r'^\s*@\w+', line):
                method_pattern_count += 1
                if method_pattern_count <= 5:
                    print(f"  Line {i+1}: {line[:60]}")
    
    print(f"\nTotal method-like patterns after build(): {method_pattern_count}")

# Show content around line 82 (where error is reported)
print(f"\n{'='*80}")
print(f"Content around line 82 (error location):")
print(f"{'='*80}")
for i in range(max(0, 81-5), min(len(lines), 82+5)):
    marker = ">>> " if i == 81 else "    "
    print(f"{marker}{i+1:4d} | {lines[i].rstrip()[:70]}")

