import os
import re

def optimize_swift_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Booleans
    content = re.sub(r'\b(var|let)\s+([a-zA-Z0-9_]+)\s*=\s*(true|false)\b', r'\1 \2: Bool = \3', content)
    
    # Strings (Empty or literal)
    content = re.sub(r'\b(var|let)\s+([a-zA-Z0-9_]+)\s*=\s*("[^"]*")\b', r'\1 \2: String = \3', content)
    
    # Integers (0 or any number without decimals, excluding if it looks like a float part)
    content = re.sub(r'\b(var|let)\s+([a-zA-Z0-9_]+)\s*=\s*([0-9]+)\b(?![\.])', r'\1 \2: Int = \3', content)
    
    # Doubles (0.0 or any decimal)
    content = re.sub(r'\b(var|let)\s+([a-zA-Z0-9_]+)\s*=\s*([0-9]+\.[0-9]+)\b', r'\1 \2: Double = \3', content)
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Optimized typing in: {filepath}")

for root, _, files in os.walk('motorsports'):
    for file in files:
        if file.endswith('.swift'):
            optimize_swift_file(os.path.join(root, file))

print("Done optimizing types!")
