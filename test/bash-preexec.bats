#!/usr/bin/env bats

setup() {
  source "${BATS_TEST_DIRNAME}/../bash-preexec.sh"
}

test_echo() {
  echo "test echo"
}

test_preexec_echo() {
  echo "$1"
}

@test "No functions defined for preexec should simply return" {
    run 'preexec_invoke_exec'
    [[ $status == 0 ]]
    [[ -z "$output" ]]
}

@test "precmd should execute a function once" {
    precmd_functions+=(test_echo)
    run 'precmd_invoke_cmd'
    [[ $status == 0 ]]
    [[ "$output" == "test echo" ]]
}

@test "preexec should execute a function with the last command in our history" {
    preexec_functions+=(test_preexec_echo)
    preexec_interactive_mode="on"
    git_command="git commit -a -m 'commiting some stuff'"
    history -s $git_command

    run 'preexec_invoke_exec'
    [[ $status == 0 ]]
    [[ "$output" == "$git_command" ]]
}

@test "preexec should execute multiple functions in the order added to their arrays" {
    fun_1() { echo "$1 one"; }
    fun_2() { echo "$1 two"; }
    preexec_functions+=(fun_1)
    preexec_functions+=(fun_2)
    preexec_interactive_mode="on"
    history -s "fake command"

    run 'preexec_invoke_exec'
    [[ $status == 0 ]]
    [[ "${lines[0]}" == "fake command one" ]]
    [[ "${lines[1]}" == "fake command two" ]]
}

@test "preecmd should execute multiple functions in the order added to their arrays" {
    fun_1() { echo "one"; }
    fun_2() { echo "two"; }
    precmd_functions+=(fun_1)
    precmd_functions+=(fun_2)

    run 'precmd_invoke_cmd'
    [[ $status == 0 ]]
    [[ "${lines[0]}" == "one" ]]
    [[ "${lines[1]}" == "two" ]]
}
