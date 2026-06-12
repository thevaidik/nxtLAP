import sys

file_path = "NxtLAP.xcodeproj/project.pbxproj"
uuids_to_remove = [
    "D106053172F6D6ECDD86DA95",
    "267A79773E8FE0777AD164E7",
    "9F8884DD93CC7A7DC1B5409C",
    "EC6037B5291AD87C7B403345",
    "A0A08F889A354E9B10E96E5D"
]

with open(file_path, 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if any(uuid in line for uuid in uuids_to_remove):
        continue
    new_lines.append(line)

with open(file_path, 'w') as f:
    f.writelines(new_lines)

print("Removed duplicate build file references!")
