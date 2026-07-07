#!/bin/python

import os
import sys
from pathspec import PathSpec
from pathspec.patterns import GitWildMatchPattern


def read_file(file_path):
    """Read and return the content of a file."""
    with open(file_path, "r", encoding="utf-8") as file:
        return file.read()


def write_to_output(output_file, content, file_path):
    """Write the content of a file to the output file with a header."""
    output_file.write(f"=== File: {file_path} ===\n")
    output_file.write(content)
    output_file.write("\n\n")


def load_gitignore(directory):
    """Load .gitignore files and return a PathSpec object."""
    gitignore_path = os.path.join(directory, ".gitignore")
    spec = PathSpec.from_lines(GitWildMatchPattern, [])
    if os.path.exists(gitignore_path):
        with open(gitignore_path, "r", encoding="utf-8") as f:
            spec = PathSpec.from_lines(GitWildMatchPattern, f.readlines())
    return spec


def traverse_directory(directory, output_file, spec):
    """Recursively traverse a directory and write file contents to the output file, respecting .gitignore."""
    for root, dirs, files in os.walk(directory):
        # Remove ignored directories
        dirs[:] = [d for d in dirs if not spec.match_file(os.path.join(root, d))]

        for file_name in files:
            file_path = os.path.join(root, file_name)
            if not spec.match_file(file_path):  # Skip ignored files
                try:
                    content = read_file(file_path)
                    write_to_output(output_file, content, file_path)
                except Exception as e:
                    print(f"Error reading {file_path}: {e}")


def main():
    # Define the directory to traverse and the output file
    codebase_directory = sys.argv[1]
    output_file_path = sys.argv[2]

    # Load .gitignore rules
    spec = load_gitignore(codebase_directory)

    if output_file_path == "-":
        traverse_directory(codebase_directory, sys.stdout, spec)
    else:
        # Open the output file and start traversing the directory
        with open(output_file_path, "w", encoding="utf-8") as output_file:
            traverse_directory(codebase_directory, output_file, spec)


if __name__ == "__main__":
    main()
