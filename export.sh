#!/bin/bash

if [ -f .env ]; then
   while IFS= read -r line; do
       export "$line"
   done < .env
   echo "Environment variables from .env file have been exported."
else
   echo "Error: The .env file does not exist."
fi
