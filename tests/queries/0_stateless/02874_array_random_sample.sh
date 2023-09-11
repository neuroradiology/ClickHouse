#!/usr/bin/env bash

CUR_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../shell_config.sh
. "$CUR_DIR"/../shell_config.sh

# Initialize variables
total_tests=0
passed_tests=0


# Test Function for Integer Arrays
run_integer_test() {
    query_result=$(clickhouse-client -q "SELECT randomSampleFromArray([1,2,3], 2)")
    mapfile -t sorted_result < <(echo "$query_result" | tr -d '[]' | tr ',' '\n' | sort -n)
    declare -A expected_outcomes
    expected_outcomes["1 2"]=1
    expected_outcomes["1 3"]=1
    expected_outcomes["2 3"]=1
    expected_outcomes["2 1"]=1
    expected_outcomes["3 1"]=1
    expected_outcomes["3 2"]=1

    sorted_result_str=$(echo "${sorted_result[*]}" | tr ' ' '\n' | sort -n | tr '\n' ' ' | sed 's/ $//')
    if [[ -n "${expected_outcomes[$sorted_result_str]}" ]]; then
        echo "Integer Test: Passed"
        ((passed_tests++))
    else
        echo "Integer Test: Failed"
        echo "Output: $query_result"
    fi
    ((total_tests++))
}

# Test Function for String Arrays
run_string_test() {
    query_result=$(clickhouse-client -q "SELECT randomSampleFromArray(['a','b','c'], 2)")
    mapfile -t sorted_result < <(echo "$query_result" | tr -d "[]'" | tr ',' '\n' | sort)
    declare -A expected_outcomes
    expected_outcomes["a b"]=1
    expected_outcomes["a c"]=1
    expected_outcomes["b c"]=1
    expected_outcomes["b a"]=1
    expected_outcomes["c a"]=1
    expected_outcomes["c b"]=1

    sorted_result_str=$(echo "${sorted_result[*]}" | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ $//')
    if [[ -n "${expected_outcomes[$sorted_result_str]}" ]]; then
        echo "String Test: Passed"
        ((passed_tests++))
    else
        echo "String Test: Failed"
        echo "Output: $query_result"
    fi
    ((total_tests++))
}

# Test Function for Nested Arrays
run_nested_array_test() {
    query_result=$(clickhouse-client -q "SELECT randomSampleFromArray([[7,2],[3,4],[7,6]], 2)")
    # Convert to a space-separated string for easy sorting.
    converted_result=$(echo "$query_result" | tr -d '[]' | tr ',' ' ')

    # Sort the string.
    sorted_result_str=$(echo "$converted_result" | tr ' ' '\n' | xargs -n2 | sort | tr '\n' ' ' | sed 's/ $//')

    # Define all possible expected outcomes, sorted
    declare -A expected_outcomes
    expected_outcomes["7 2 3 4"]=1
    expected_outcomes["7 2 7 6"]=1
    expected_outcomes["3 4 7 6"]=1
    expected_outcomes["3 4 7 2"]=1
    expected_outcomes["7 6 7 2"]=1
    expected_outcomes["7 6 3 4"]=1

    if [[ -n "${expected_outcomes[$sorted_result_str]}" ]]; then
        echo "Nested Array Test: Passed"
        ((passed_tests++))
    else
        echo "Nested Array Test: Failed"
        echo "Output: $query_result"
        echo "Processed Output: ${sorted_result_str}"
    fi
    ((total_tests++))
}


# Test Function for K > array.size
run_higher_k_test() {
    query_result=$(clickhouse-client -q "SELECT randomSampleFromArray([1,2,3], 5)")
    mapfile -t sorted_result < <(echo "$query_result" | tr -d '[]' | tr ',' '\n' | sort -n)
    sorted_original=("1" "2" "3")

    are_arrays_equal=true
    for i in "${!sorted_result[@]}"; do
        if [[ "${sorted_result[$i]}" != "${sorted_original[$i]}" ]]; then
            are_arrays_equal=false
            break
        fi
    done

    if $are_arrays_equal; then
        echo "Higher Sample Number Test: Passed"
        ((passed_tests++))
    else
        echo "Higher Sample Number Test: Failed"
        echo "Output: $query_result"
    fi
    ((total_tests++))
}



# Run test multiple times
for i in {1..5}; do
    echo "Running iteration: $i"
    run_integer_test
    run_string_test
    run_nested_array_test
    run_higher_k_test
done

# Print overall test results
echo "Total tests: $total_tests"
echo "Passed tests: $passed_tests"
