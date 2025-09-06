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

    def run_script(self, commands):
        """Equivalent to Ruby's run_script - returns array of output lines"""
        process = subprocess.Popen(
            ["./db"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

        # Send each command (like Ruby's pipe.puts command)
        input_str = "\n".join(commands) + "\n"
        stdout, stderr = process.communicate(input=input_str)

        # Return array of lines (like Ruby's raw_output.split("\n"))
        return stdout.strip().split("\n") if stdout.strip() else []

    def match_array(self, actual, expected):
        """Compare arrays like Ruby's match_array (order doesn't matter)"""
        return sorted(actual) == sorted(expected)

    def run_test(self, test_name, commands, expected_array):
        """Run a test case - matches Ruby structure"""
        self.total_tests += 1

        try:
            result = self.run_script(commands)

            if self.match_array(result, expected_array):
                print(".", end="", flush=True)
                self.passed_tests += 1
            else:
                print("F", end="", flush=True)
                self.failed_tests += 1
                self.failures.append(
                    {"name": test_name, "expected": expected_array, "actual": result}
                )
        except Exception as e:
            print("E", end="", flush=True)
            self.failed_tests += 1
            self.failures.append({"name": test_name, "error": str(e)})

    def test_table_full(self):
        """Test that database shows error when table is full"""
        test_name = "prints error message when table is full"
        self.total_tests += 1

        try:
            # Generate script like Ruby: (1..1401).map
            script = []
            for i in range(1, 1402):
                script.append(f"insert {i} user{i} person{i}@example.com")
            script.append(".exit")

            result = self.run_script(script)

            # Check second-to-last element (like Ruby result[-2])
            if len(result) >= 2 and result[-2] == "db > Error: Table full.":
                print(".", end="", flush=True)
                self.passed_tests += 1
            else:
                print("F", end="", flush=True)
                self.failed_tests += 1
                second_last = result[-2] if len(result) >= 2 else "Not enough output"
                self.failures.append(
                    {
                        "name": test_name,
                        "expected": "db > Error: Table full.",
                        "actual": second_last,
                        "context": f"Full result length: {len(result)}, last 5: {result[-5:] if len(result) >= 5 else result}",
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
            for failure in self.failures:
                print(f"FAILURE: {failure['name']}")
                if "error" in failure:
                    print(f"Error: {failure['error']}")
                else:
                    print(f"Expected: {failure['expected']}")
                    print(f"Actual: {failure['actual']}")
                    if "context" in failure:
                        print(failure["context"])
                print("---")

        # Summary
        print()
        if self.failed_tests == 0:
            print(f"\033[32mFinished in {duration:.5f} seconds\033[0m")
            print(f"\033[32m{self.total_tests} examples, 0 failures\033[0m")
        else:
            print(f"\033[31mFinished in {duration:.5f} seconds\033[0m")
            print(
                f"\033[31m{self.total_tests} examples, {self.failed_tests} failures\033[0m"
            )


def main():
    tester = DatabaseTester()

    print("Running database tests...")

    # Test 1: Basic functionality (exactly like Ruby)
    tester.run_test(
        "inserts and retrieves a row",
        [
            "insert 1 user1 person1@example.com",
            "select",
            ".exit",
        ],
        [
            "db > Executed.",
            "db > (1, user1, person1@example.com)",
            "Executed.",
            "db > ",
        ],
    )

    # Test 2: Maximum string lengths (exactly like Ruby)
    long_username = "a" * 32
    long_email = "a" * 255
    tester.run_test(
        "allows inserting strings that are the maximum length",
        [
            f"insert 1 {long_username} {long_email}",
            "select",
            ".exit",
        ],
        [
            "db > Executed.",
            f"db > (1, {long_username}, {long_email})",
            "Executed.",
            "db > ",
        ],
    )

    # Test 3: String too long (exactly like Ruby)
    long_username = "a" * 33
    long_email = "a" * 256
    tester.run_test(
        "prints error message if strings are too long",
        [
            f"insert 1 {long_username} {long_email}",
            "select",
            ".exit",
        ],
        [
            "db > String is too long.",
            "db > Executed.",
            "db > ",
        ],
    )

    # Test 4: Negative ID validation (exactly like Ruby)
    tester.run_test(
        "prints an error message if id is negative",
        [
            "insert -1 cstack foo@bar.com",
            "select",
            ".exit",
        ],
        [
            "db > ID must be positive.",
            "db > Executed.",
            "db > ",
        ],
    )

    # Test 5: Table full scenario
    tester.test_table_full()

    tester.print_summary()
    return tester.failed_tests


if __name__ == "__main__":
    sys.exit(main())
