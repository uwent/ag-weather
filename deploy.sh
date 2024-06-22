#!/bin/bash

declare -A deployments

# Select deployment servers
servers=()
read -p "=> Deploy to 1) staging, 2) production: " selection
if [[ $selection =~ [1] ]]; then servers+=("staging"); fi
if [[ $selection =~ [2] ]]; then servers+=("production"); fi
if [[ ${#servers[@]} -eq 0 ]]; then
    echo "You must select at least one server."
    exit
fi

# Select projects for deployment
projects=("ag-weather" "ag-vdifn" "soils-ag-wx" "wisp")

echo
echo "Available projects:"
for i in "${!projects[@]}"; do
    echo "$((i+1)). ${projects[i]}"
done

read -p "=> Enter project numbers to deploy: " selected_projects
echo

for (( i=0; i<${#selected_projects}; i++ )); do
    num=${selected_projects:$i:1}
    if [[ $num =~ [1-4] ]]; then
        project=${projects[$((num-1))]}
        
        # Get branch for this project
        read -p "Git branch for ${project}: " branch
        
        # Store deployment info
        deployments[$project]="branch:$branch"
    fi
done

if [[ ${#deployments[@]} -eq 0 ]]; then
    echo "No projects selected for deployment."
    exit
fi

# Execute deployments
statuses=()
echo
for project in "${!deployments[@]}"; do
    IFS=';' read -r -a info <<< "${deployments[$project]}"
    branch="${info[1]#branch:}"
    
    for server in "${servers[@]}"; do
        echo "Deploying $project to $server..."
        cd ~/"code/$project" || { echo "Failed to change directory to $project"; exit; }
        
        if [ -n "$branch" ]; then
            BRANCH="$branch" cap "$server" deploy
        else
            cap "$server" deploy
        fi
        
        if [ $? -eq 0 ]; then
            statuses+=("$project deployed successfully to $server")
        else
            echo "Deployment of $project to $server failed!"
            exit
        fi
        
        cd - > /dev/null || exit
        echo
    done
done

# Report deployments
for status in "${statuses[@]}"; do
    echo $status
done
