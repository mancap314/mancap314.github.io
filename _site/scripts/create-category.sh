#!/bin/bash

# Script to create a category 
# Just provide the name of the category as first parameter

cd ../_category/

name="${1,,}"  # convert first arg (category name) to lower case

if [ -f ${name}.md ] ; then
  echo Category \"${name}\" already exists, exit
  exit 1
fi


capitalized=${name^}  # capitalize first letter
touch ${name}.md
echo --- >> ${name}.md
echo title: ${name} >> ${name}.md
echo category: ${capitalized} >> ${name}.md
echo permalink: /${name} >> ${name}.md
echo --- >> ${name}.md

