#!/bin/bash

MYDIR="$(dirname "$(readlink -f "$0")")"

source "$MYDIR/../kvm-include.sh"

function test_ip_to_mac()
{
    log_title "Testing ip_to_mac function"

    local ip="192.168.100.2"
    local expected_mac="52:54:C0:A8:64:02"

    ip_to_mac "$ip"
    if [ $? -ne 0 ]; then
        log_error "ip_to_mac function failed"
        return 1
    fi
    if [ "$RETURNED_MAC" == "$expected_mac" ]; then
        log_info "ip_to_mac test passed: $ip -> $RETURNED_MAC"
    else
        log_error "ip_to_mac test failed. Expected $expected_mac, got $RETURNED_MAC"
    fi

    local invalid_ip="192.168.100.255.2"
    ip_to_mac "$invalid_ip" 2> /dev/null
    if [ $? -eq 0 ]; then
        log_error "ip_to_mac function should have failed for invalid IP: $invalid_ip"
        return 1
    else
        log_info "ip_to_mac test passed for invalid IP: $invalid_ip"
    fi
}

function run_all_tests()
{
    test_ip_to_mac
}

function log_help()
{
    cat <<EOF
This script is a test suite for the kvm-include.sh functions.

Usage: $0 <action> [OPTIONS]

Actions:
  ip_to_mac       Test the ip_to_mac function

Options:
    -h, --help     Show this help message and exit
EOF
}

function main()
{
    if [ "$#" -eq 0 ]; then
        run_all_tests
        return 1
    fi

    case "$1" in
        ip_to_mac)
            test_ip_to_mac
            ;;
        *)
            log_error "Unknown test: $1" 
            return 1
            ;;
    esac
}

main "$@"

