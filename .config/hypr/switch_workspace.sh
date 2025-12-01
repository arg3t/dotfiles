#!/bin/bash

operation=$1
workspace=$2

monitor_id=$(hyprctl activeworkspace | grep "monitorID" | awk '{print $2}')

if [[ $operation == "switch" ]]; then
  workspace_id=$(($monitor_id * 10 + $workspace))
	hyprctl dispatch moveworkspacetomonitor $workspace_id $monitor_id;
	hyprctl dispatch workspace $workspace_id;
fi
if [[ $operation == "move" ]]; then
  workspace_id=$(($monitor_id * 10 + $workspace))
	hyprctl dispatch moveworkspacetomonitor $workspace_id $monitor_id;
	hyprctl dispatch movetoworkspacesilent $workspace_id;
fi
if [[ $operation == "togglespecial" ]]; then
  workspace_id="${monitor_id}_${workspace}"
	hyprctl dispatch togglespecialworkspace $workspace_id;
fi
