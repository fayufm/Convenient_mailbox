# -*- coding: utf-8 -*-
"""系统地修复Index.ets的结构问题"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print("Step 1: 移除错误添加的catch块 (在build方法内部)...")

# Find and remove the misplaced catch block (lines 6578-6581)
# These lines are:
# 6578:    } catch (error) {
# 6579:      const err = error as Error
# 6580:      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
# 6581:        'updateUITexts error: %{public}s', err.message)

removed_count = 0
i = 0
while i < len(lines):
    line = lines[i]
    # Find the misplaced catch block
    if '} catch (error) {' in line and i > 6570 and i < 6590:
        # This is the misplaced catch - remove it and next 3 lines
        print(f"  Removing misplaced catch at line {i+1}: {line.strip()[:60]}")
        del lines[i:i+4]  # Remove 4 lines
        removed_count += 4
        break  # Only one misplaced catch
    i += 1

print(f"  Removed {removed_count} lines")

print("\nStep 2: 找到updateUITexts方法结束位置...")

# Find updateUITexts method
for i, line in enumerate(lines):
    if 'updateUITexts(language: string) {' in line:
        updateuitexts_start = i
        print(f"  updateUITexts starts at line {i+1}")
        break

# Find where object literal ends (should have 'featureDescription')
for i in range(updateuitexts_start, len(lines)):
    if "'featureDescription':" in lines[i] and lines[i].strip().endswith('}'):
        obj_end = i
        print(f"  Object literal ends at line {i+1}")
        break

# The next lines should be hilog.info, then method closing }
print(f"\n  Lines after object literal:")
for i in range(obj_end, min(obj_end + 5, len(lines))):
    print(f"    {i+1}: {lines[i].rstrip()[:70]}")

print("\nStep 3: 重构updateUITexts方法结束部分...")

# The structure should be:
# Line X: 'featureDescription': '...' }
# Line X+1:    } catch (error) { ...
# Line X+2:      ...error handling...
# Line X+3:    }
# Line X+4:  }  // end of updateUITexts method

# Currently we have:
# 6565:     'featureDescription': '...' }
# 6566:     hilog.info(...)
# 6567:       '...', language)
# 6568:   }

# We need to:
# 1. Keep the object literal end (line 6565: ... })
# 2. Add catch block
# 3. Add method closing brace
# 4. Remove the hilog.info (it doesn't belong to updateUITexts - it was part of a corrupted section)

# Find the lines again (after removal)
for i, line in enumerate(lines):
    if "'featureDescription':" in line and line.strip().endswith('}'):
        obj_end = i
        break

# Check what's after
if 'hilog.info' in lines[obj_end + 1]:
    # Remove the hilog.info lines (they are corrupted/misplaced)
    print(f"  Removing corrupted hilog.info at lines {obj_end+2}-{obj_end+3}")
    del lines[obj_end + 1:obj_end + 3]

# Now add proper try-catch closing and method closing
catch_and_close = [
    "    } catch (error) {\n",
    "      const err = error as Error\n",
    "      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,\n",
    "        'updateUITexts error: %{public}s', err.message)\n",
    "    }\n",  # Close catch
    "  }\n",   # Close updateUITexts method
]

lines[obj_end + 1:obj_end + 1] = catch_and_close

print(f"\n  Added catch block and method closing at line {obj_end + 2}")

print("\nStep 4: 验证结构...")
# Show the result
for i in range(obj_end, min(obj_end + 12, len(lines))):
    marker = ""
    if i == obj_end:
        marker = "OBJ_END  "
    elif obj_end < i < obj_end + 7:
        marker = "ADDED    "
    else:
        marker = "         "
    print(f"  {marker}{i+1}: {lines[i].rstrip()[:70]}")

# Write back
with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8', errors='ignore') as f:
    f.writelines(lines)

print(f"\n✅ 完成！Index.ets结构已修复")
print(f"   总行数: {len(lines)}")

