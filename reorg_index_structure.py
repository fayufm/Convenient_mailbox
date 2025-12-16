# -*- coding: utf-8 -*-
"""重新组织Index.ets的结构：将所有@Builder方法移到build()之前"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print("Step 1: 分析当前文件结构...")

# Find key positions
struct_start = None
build_start = None
build_end = None
methods_after_build_start = None
struct_end = None

for i, line in enumerate(lines):
    if 'struct Index {' in line:
        struct_start = i
        print(f"  struct Index starts at line {i+1}")
    elif i == 980 and 'build()' in line:  # build() at line 981
        build_start = i
        print(f"  build() starts at line {i+1}")
    elif i == 1325:  # build() ends at line 1326
        build_end = i
        print(f"  build() ends at line {i+1}")
    elif build_end and not methods_after_build_start and '@Builder' in line:
        methods_after_build_start = i
        print(f"  First @Builder after build() at line {i+1}")
    elif struct_end is None and line.strip() == '}' and i > (build_end or 1000):
        # This might be the struct end
        pass

# Find the actual struct end (last closing brace)
brace_count = 0
for i in range(struct_start, len(lines)):
    for char in lines[i]:
        if char == '{':
            brace_count += 1
        elif char == '}':
            brace_count -= 1
            if brace_count == 0:
                struct_end = i
                break
    if struct_end:
        break

print(f"  struct Index ends at line {struct_end+1}")

# Extract sections
print("\nStep 2: 提取各个部分...")
imports_and_types = lines[:struct_start+1]  # Everything before struct Index
state_vars_and_early_methods = lines[struct_start+1:build_start]  # State vars and methods before build()
build_method = lines[build_start:build_end+1]  # build() method
methods_after_build = lines[build_end+1:struct_end]  # Methods that should be moved
struct_close = lines[struct_end:]  # Closing brace and anything after

print(f"  - Imports and types: {len(imports_and_types)} lines")
print(f"  - State vars and early methods: {len(state_vars_and_early_methods)} lines")
print(f"  - build() method: {len(build_method)} lines")
print(f"  - Methods after build (TO MOVE): {len(methods_after_build)} lines")
print(f"  - Struct close: {len(struct_close)} lines")

# Reorganize
print("\nStep 3: 重新组织结构...")
new_content = (
    imports_and_types +  # struct Index {
    state_vars_and_early_methods +  # State variables and methods
    methods_after_build +  # @Builder methods (moved before build)
    ["\n", "  // ==================== 主界面构建 (build方法必须最后) ====================\n", "\n"] +
    build_method +  # build() method (now at the end)
    struct_close  # }
)

# Write to file
print("\nStep 4: 写入新文件...")
with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8', errors='ignore') as f:
    f.writelines(new_content)

print(f"\n✅ 完成！Index.ets已重新组织")
print(f"   总行数: {len(new_content)}")
print(f"   build()方法现在位于: line {len(imports_and_types) + len(state_vars_and_early_methods) + len(methods_after_build) + 3}")

