#!/bin/bash

# supress D-Bus fatal warnings
export DBUS_FATAL_WARNINGS=0

# Workaround for connection failure with built-in updater
wget -N http://www.hamradiotrainer.de/download/de.amateurfunk.etq -O ~/HamRadioTrainer/data/de.amateurfunk.etq

/usr/bin/wine ~/HamRadioTrainer/start-hamradiotrainer.exe
