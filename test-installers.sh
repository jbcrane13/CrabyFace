#!/bin/bash

# Test script for Task Master AI installers

echo "Testing Task Master AI Installers"
echo "================================="
echo

# Test 1: Basic installer help
echo "Test 1: Basic installer help"
node install-taskmaster.js --help > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Basic installer help works"
else
    echo "❌ Basic installer help failed"
fi
echo

# Test 2: Advanced installer help
echo "Test 2: Advanced installer help"
node install-taskmaster-advanced.js --help > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Advanced installer help works"
else
    echo "❌ Advanced installer help failed"
fi
echo

# Test 3: Bash installer help
echo "Test 3: Bash installer help"
./install-taskmaster.sh --help > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Bash installer help works"
else
    echo "❌ Bash installer help failed"
fi
echo

# Test 4: Basic installer dry run
echo "Test 4: Basic installer dry run"
node install-taskmaster.js --dry-run --yes --silent
if [ $? -eq 0 ]; then
    echo "✅ Basic installer dry run works"
else
    echo "❌ Basic installer dry run failed"
fi
echo

# Test 5: Bash installer dry run
echo "Test 5: Bash installer dry run"
./install-taskmaster.sh --dry-run --yes > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Bash installer dry run works"
else
    echo "❌ Bash installer dry run failed"
fi
echo

echo "Test Summary"
echo "============"
echo "All basic tests completed. Check results above."