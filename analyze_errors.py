# -*- coding: utf-8 -*-
import re
from collections import Counter

# Remove ANSI color codes
def strip_ansi(text):
    ansi_escape = re.compile(r'\x1B\[[0-9;]*m')
    return ansi_escape.sub('', text)

# File is UTF-16 LE encoded
with open('current_build_report.txt', 'r', encoding='utf-16-le', errors='ignore') as f:
    lines = [strip_ansi(line) for line in f.readlines()]

# Extract all errors
errors = []
i = 0
while i < len(lines):
    line = lines[i].strip()
    # Match error line: "1 ERROR: 10605008 ArkTS Compiler Error"
    error_match = re.match(r'^(\d+) ERROR:\s*(\d+) ArkTS Compiler Error', line)
    if error_match:
        error_num = error_match.group(1)
        error_code = error_match.group(2)
        # Next line should be "Error Message: ..."
        if i + 1 < len(lines) and lines[i + 1].strip().startswith('Error Message:'):
            error_msg = lines[i + 1].strip().replace('Error Message: ', '').split(' At File:')[0].strip()
            # Get file location
            file_loc = ''
            if ' At File:' in lines[i + 1]:
                file_loc = lines[i + 1].split(' At File:')[1].strip()
            errors.append((error_num, error_code, error_msg, file_loc))
            i += 2
        else:
            i += 1
    else:
        i += 1

# Count by error type (message)
error_messages = Counter([err[2] for err in errors])

# Count by error code
error_codes = Counter([err[1] for err in errors])

    print("=" * 80)
print("错误统计分析 (Error Analysis)")
    print("=" * 80)
    print(f"\n总错误数: {len(errors)}")
print(f"\n按错误代码统计:")
for code, count in error_codes.most_common():
    print(f"  {code}: {count}个")

print(f"\n按错误类型统计 (前30个):")
for msg, count in error_messages.most_common(30):
    # Truncate long messages
    display_msg = msg if len(msg) < 70 else msg[:67] + "..."
    print(f"  [{count:4d}] {display_msg}")

# Analyze specific error patterns
print(f"\n特定错误模式:")

# Cannot find name
cannot_find = sum([c for m, c in error_messages.items() if m.startswith("Cannot find name")])
print(f"  - 'Cannot find name' 错误: {cannot_find}个")

# Object is possibly undefined
undefined_obj = sum([c for m, c in error_messages.items() if "Object is possibly 'undefined'" in m])
print(f"  - 'Object is possibly undefined' 错误: {undefined_obj}个")

# Type errors
type_errors = sum([c for m, c in error_messages.items() if "'string' only refers to a type" in m or ("Type" in m and "being used as a value" in m)])
print(f"  - 类型错误 (Type errors): {type_errors}个")

# Critical build method error
build_error = sum([c for m, c in error_messages.items() if "must have at least and at most one 'build' method" in m])
print(f"  - 关键的build方法错误: {build_error}个")

# Invalid character / encoding errors
encoding_errors = sum([c for m, c in error_messages.items() if "No value exists in scope" in m or "鎴?" in m or "鍐?" in m or "瑜?" in m or "閿?" in m])
print(f"  - 编码/乱码相关错误: {encoding_errors}个")

# Async errors
async_errors = sum([c for m, c in error_messages.items() if "Cannot find name 'async'" in m])
print(f"  - async关键字错误: {async_errors}个")
    
    print("\n" + "=" * 80)
