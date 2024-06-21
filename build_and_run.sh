#!/bin/env bash

compilerPath='/home/ben/bin/PlaydateSDK-2.5.0/bin/pdc'
simulatorPath='/home/ben/bin/PlaydateSDK-2.5.0/bin/PlaydateSimulator'
sourcePath='./Source'
outputPath='./breakout.pdx'

echo "Compiler path:  $compilerPath"
echo "Simulator path: $simulatorPath"
echo "Source path:    $sourcePath"
echo "Output path:    $outputPath"
echo ""

echo "Compile source..."
$compilerPath $sourcePath $outputPath

echo "Opening simulator..."
$simulatorPath $outputPath
