#!/usr/bin/env python3
# -*- coding: utf-8 -*-

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Track quotes line by line
single_count = 0
double_count = 0
backtick_count = 0
escaped = False

for line_num, line in enumerate(lines, 1):
    line_single = 0
    line_double = 0
    line_backtick = 0
    
    for i, char in enumerate(line):
        if escaped:
            escaped = False
            continue
        
        if char == '\\':
            escaped = True
            continue
        
        if char == "'":
            single_count += 1
            line_single += 1
        elif char == '"':
            double_count += 1
            line_double += 1
        elif char == '`':
            backtick_count += 1
            line_backtick += 1
    
    # Check for imbalance starting from line 12280
    if line_num >= 12280:
        if single_count % 2 == 1:
            print(f'Line {line_num}: UNBALANCED singles (total={single_count}, line={line_single})')
            print(f'  {line.rstrip()[:100]}')
        if double_count % 2 == 1:
            print(f'Line {line_num}: UNBALANCED doubles (total={double_count}, line={line_double})')
        if backtick_count % 2 == 1:
            print(f'Line {line_num}: UNBALANCED backticks (total={backtick_count}, line={line_backtick})')

print(f'\nFinal counts:')
print(f'  Single quotes: {single_count} ({"balanced" if single_count % 2 == 0 else "UNBALANCED"})')
print(f'  Double quotes: {double_count} ({"balanced" if double_count % 2 == 0 else "UNBALANCED"})')
print(f'  Backticks: {backtick_count} ({"balanced" if backtick_count % 2 == 0 else "UNBALANCED"})')

