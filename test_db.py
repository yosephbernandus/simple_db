#!/usr/bin/env python3
import subprocess
import sys
import time


class DatabaseTester:
    def __init__(self):
        self.total_tests = 0
        self.passed_tests = 0
        self.failed_tests = 0
        self.failures = []
        self.start_time = time.time()

    def run_db_command(self, commands):
        process = subprocess.Popen(
            ["./db"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

        if isinstance(commands, list):
            input_str = "\n".join(commands) + "\n"
        else:
            input_str = commands

        stdout, stderr = process.communicate(input=input_str)
        return stdout.strip()

    def run_test(self, test_name, commands, expected):
        self.total_tests += 1

        try:
            actual = self.run_db_command(commands)

            if actual == expected:
                print(".", end="", flush=True)
                self.passed_tests += 1
            else:
                print("F", end="", flush=True)
                self.failed_tests += 1
                self.failures.append(
                    {"name": test_name, "expected": expected, "actual": actual}
                )
        except Exception as e:
            print("E", end="", flush=True)
            self.failed_tests += 1
            self.failures.append({"name": test_name, "error": str(e)})

    def test_max_string_length(self):
        """Test inserting strings at maximum allowed length"""
        test_name = "allows inserting strings that are the maximum length"

        # Generate maximum length strings
        long_username = "a" * 32  # 32 characters
        long_email = "a" * 255  # 255 characters

        commands = [f"insert 1 {long_username} {long_email}", "select", ".exit"]

        expected = (
            f"db > Executed.\ndb > (1, {long_username}, {long_email})\nExecuted.\ndb > "
        )

        self.run_test(test_name, commands, expected)

    def test_table_full(self):
        """Test that database shows error when table is full"""
        test_name = "prints error message when table is full"
        self.total_tests += 1

        try:
            # Generate 1401 insert commands
            commands = []
            for i in range(1, 1402):
                commands.append(f"insert {i} user{i} person{i}@example.com")
            commands.append(".exit")

            # Run the test
            result = self.run_db_command(commands)
            result_lines = result.split("\n")

            # Check second-to-last line
            if len(result_lines) >= 2:
                second_last_line = result_lines[-2]
                if second_last_line == "db > Error: Table full.":
                    print(".", end="", flush=True)
                    self.passed_tests += 1
                else:
                    print("F", end="", flush=True)
                    self.failed_tests += 1
                    self.failures.append(
                        {
                            "name": test_name,
                            "expected": "db > Error: Table full.",
                            "actual": second_last_line,
                            "context": f"Last 5 lines: {result_lines[-5:]}",
                        }
                    )
            else:
                print("F", end="", flush=True)
                self.failed_tests += 1
                self.failures.append(
                    {
                        "name": test_name,
                        "error": f"Not enough output lines. Got: {result_lines}",
                    }
                )

        except Exception as e:
            print("E", end="", flush=True)
            self.failed_tests += 1
            self.failures.append({"name": test_name, "error": str(e)})

    def print_summary(self):
        print()  # New line after dots

        duration = time.time() - self.start_time

        # Show failures
        if self.failures:
            print("\nFailures:")
            for i, failure in enumerate(self.failures, 1):
                print(f"\n{i}) {failure['name']}")
                if "error" in failure:
                    print(f"   Error: {failure['error']}")
                else:
                    print(f"   Expected: {repr(failure['expected'])}")
                    print(f"   Actual:   {repr(failure['actual'])}")
                    if "context" in failure:
                        print(f"   Context: {failure['context']}")

        # Summary
        print(f"\nFinished in {duration:.5f} seconds")

        if self.failed_tests == 0:
            print(f"\033[32m{self.total_tests} examples, 0 failures\033[0m")
        else:
            print(
                f"\033[31m{self.total_tests} examples, {self.failed_tests} failures\033[0m"
            )


def main():
    tester = DatabaseTester()

    print("Running database tests...")

    # Test 1: Basic functionality
    tester.run_test(
        "inserts and retrieves a row",
        ["insert 1 user1 person1@example.com", "select", ".exit"],
        "db > Executed.\ndb > (1, user1, person1@example.com)\nExecuted.\ndb > ",
    )

    # Test 2: Maximum string lengths
    tester.test_max_string_length()

    # Test 3: Table full scenario
    tester.test_table_full()

    tester.print_summary()
    return tester.failed_tests


if __name__ == "__main__":
    sys.exit(main())
