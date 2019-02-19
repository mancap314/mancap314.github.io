#!/bin/bash
# Script to create a category 

cd ../_category/

# name="${1,,}"  # convert first arg (category name) to lower case
echo "Enter category name:"
while true; do
  read name
  category_name=$( echo ${name} | sed 's/[^a-zA-Z0-9]\+/-/g' | iconv -f utf8 -t ascii//TRANSLIT//IGNORE | tr [:upper:] [:lower:] )
  [[ ${category_name: -1} == "-" ]] && category_name=${category_name%?}
  if [[ -z "$category_name" ]]; then
    echo category name must contain at least one alphanumerical character, please enter another name:
  elif [[ -f ${category_name}.md ]]; then
    echo Category \"${category_name}\" already exists, please enter another name:
  else
    break
  fi
done

echo Enter description \(optional\):
read description

# Capitalize the first letter of each word in category_name and lower the others
capitalized=$( echo ${name}  | sed 's/[^a-zA-Z0-9]\+/ /g' | tr [:upper:] [:lower:] | sed 's/\(^\| \)\([a-z]\)/\1\u\2/g'  )

touch ${category_name}.md
echo --- >> ${category_name}.md
echo title: ${category_name} >> ${category_name}.md
echo category: ${capitalized} >> ${category_name}.md
[[ ! -z description ]] && echo description: ${description} >> ${category_name}.md
echo permalink: /${category_name}/ >> ${category_name}.md
echo --- >> ${category_name}.md

echo category ${category_name} created with following properties:
while IFS= read -r line
do
  echo "$line"
done < ${category_name}.md
