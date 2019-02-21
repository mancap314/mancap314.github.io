#!/bin/bash
# Script to create a category 

cd ../_category/

echo "Enter category name:"
while true; do
  read name
  category_name=$( echo ${name} | sed 's/[^a-zA-Z0-9 ]\+/-/g' | sed 's/[ ]\+/ /g' | sed 's/[ ]\+-//g' )
  title_name=$( echo ${category_name} | sed 's/[ ]\+/-/g' | tr [:upper:] [:lower:]  )
  file_name=$( echo ${title_name} | iconv -f utf8 -t ascii//TRANSLIT//IGNORE )
  if [[ -z $( echo ${title_name} | tr -d '-' ) ]]; then
    echo category name must contain at least one alphanumerical character, please enter another name:
  elif [[ -f ${file_name}.md ]]; then
    echo Category \"${category_name}\" already exists, please enter another name:
  else
    break
  fi
done

echo Enter description \(optional\):
read description

touch ${file_name}.md
echo --- >> ${file_name}.md
echo title: ${title_name} >> ${file_name}.md
echo category: ${category_name} >> ${file_name}.md
[[ ! -z description ]] && echo description: ${description} >> ${file_name}.md
echo permalink: /${title_name}/ >> ${file_name}.md
echo --- >> ${file_name}.md

echo category \'${category_name}\' created in \'_category/${file_name}.md\' with following properties:
while IFS= read -r line
do
  echo "$line"
done < ${file_name}.md
