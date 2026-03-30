import json
import sys

def load_jsonl(file_path):
    try:
        with open(file_path, 'r') as f:
            return [json.loads(line) for line in f if line.strip()]
    except Exception as e:
        print(f"Error loading {file_path}: {e}")
        sys.exit(1)

def compare(a, b, path=""):
    differences = []

    if isinstance(a, dict) and isinstance(b, dict):
        for key in a:
            new_path = f"{path}.{key}" if path else key
            if key not in b:
                differences.append(f"{new_path}: Missing in B")
            else:
                differences.extend(compare(a[key], b[key], new_path))
    elif isinstance(a, list) and isinstance(b, list):
        if a != b:
            differences.append(f"{path}: List differs\n  Expected: {a}\n  Actual:   {b}")
    else:
        if a != b:
            differences.append(f"{path}: Value differs\n  Expected: {a}\n  Actual:   {b}")

    return differences

def main():
    if len(sys.argv) != 3:
        print("Usage: python compare_jsonl.py <A.jsonl> <B.jsonl>")
        print("Compares two JSONL files line by line and checks B.jsonl is a superset of A.jsonl.")
        sys.exit(1)

    a_file, b_file = sys.argv[1], sys.argv[2]

    a_data = load_jsonl(a_file)
    b_data = load_jsonl(b_file)

    if len(a_data) != len(b_data):
        print(f"Line count mismatch: {a_file} has {len(a_data)} lines, {b_file} has {len(b_data)} lines.")
        sys.exit(1)

    differences_found = False

    for line_number, (a_obj, b_obj) in enumerate(zip(a_data, b_data), start=1):
        differences = compare(a_obj, b_obj)
        if differences:
            differences_found = True
            print(f"\nA.jsonl line {line_number} vs B.jsonl line {line_number}: Differences found")
            print("  Differences:")
            for diff in differences:
                print(f"    - {diff}")

    if differences_found:
        sys.exit(1)
    else:
        print("All lines match (A ⊆ B).")
        sys.exit(0)

if __name__ == "__main__":
    main()
