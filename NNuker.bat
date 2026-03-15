@echo off
set "ps_script=%~dp0NNuker.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%ps_script%\"' -Verb RunAs}"
