#!/usr/bin/env bats

setup() {
  __bp_delay_install="true"
  source "${BATS_TEST_DIRNAME}/../bash-preexec.sh"
}

test_echo() {
  echo "test echo"
}

test_preexec_echo() {
  echo "$1"
}

@test "prexec_and_precmd_install should exit with 1 if we're not using bash" {
  unset BASH_VERSION
  run 'preexec_and_precmd_install'
  [[ $status == 1 ]]
  [[ -z "$output" ]]
}

@test "prexec_and_precmd_install should exit if it's already installed" {
  PROMPT_COMMAND="some_other_function; __bp_precmd_invoke_cmd;"
  run 'preexec_and_precmd_install'
  [[ $status == 1 ]]
  [[ -z "$output" ]]
}

@test "No functions defined for preexec should simply return" {
    run '__bp_preexec_invoke_exec'
    [[ $status == 0 ]]
    [[ -z "$output" ]]
}

@test "precmd should execute a function once" {
    precmd_functions+=(test_echo)
    run '__bp_precmd_invoke_cmd'
    [[ $status == 0 ]]
    [[ "$output" == "test echo" ]]
}

@test "preexec should execute a function with the last command in our history" {
    preexec_functions+=(test_preexec_echo)
    __bp_preexec_interactive_mode="on"
    git_command="git commit -a -m 'commiting some stuff'"
    history -s $git_command

    run '__bp_preexec_invoke_exec'
    [[ $status == 0 ]]
    [[ "$output" == "$git_command" ]]
}

@test "preexec should execute multiple functions in the order added to their arrays" {
    fun_1() { echo "$1 one"; }
    fun_2() { echo "$1 two"; }
    preexec_functions+=(fun_1)
    preexec_functions+=(fun_2)
    __bp_preexec_interactive_mode="on"
    history -s "fake command"

    run '__bp_preexec_invoke_exec'
    [[ $status == 0 ]]
    [[ "${lines[0]}" == "fake command one" ]]
    [[ "${lines[1]}" == "fake command two" ]]
}

@test "preecmd should execute multiple functions in the order added to their arrays" {
    fun_1() { echo "one"; }
    fun_2() { echo "two"; }
    precmd_functions+=(fun_1)
    precmd_functions+=(fun_2)

    run '__bp_precmd_invoke_cmd'
    [[ $status == 0 ]]
    [[ "${lines[0]}" == "one" ]]
    [[ "${lines[1]}" == "two" ]]
}

@test "in_prompt_command should detect if a command is part of PROMPT_COMMAND" {

    PROMPT_COMMAND="precmd_invoke_cmd; something;"
    run '__bp_in_prompt_command' "something"
    [[ $status == 0 ]]

    run '__bp_in_prompt_command' "something_else"
    [[ $status == 1 ]]

    # Should trim commands and arguments here.
    PROMPT_COMMAND=" precmd_invoke_cmd ; something ; some_stuff_here;"
    run '__bp_in_prompt_command' " precmd_invoke_cmd "
    [[ $status == 0 ]]

    PROMPT_COMMAND=" precmd_invoke_cmd ; something ; some_stuff_here;"
    run '__bp_in_prompt_command' " not_found"
    [[ $status == 1 ]]

}
