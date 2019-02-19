#!/bin/bash

DEFAULT_AUTHOR="Manuel Capel"  # default author name

while true; do
  echo Enter title \(for article\)
  read line
  if [[ ! -z "$line" ]]; then
    article_title=$line
    file_title=$( echo ${article_title} | sed 's/[^a-zA-Z0-9]\+/-/g' | iconv -f utf8 -t ascii//TRANSLIT//IGNORE | tr [:upper:] [:lower:] )
    [[ ${file_title: -1} == "-" ]] && file_title=${file_title%?}
    if [[ -z "$file_title" ]]; then
      echo article title must contain at least one alphanumerical character
    else
      break
    fi
  else
    echo article title cannot be empty
  fi
done

existing_titles=()
for filename in ../_posts/*; do
  if [ -f ${filename} ]; then
    aname=$(basename "$filename" | cut -d. -f1 | cut -c12- )
    existing_titles+=(${aname})
  fi
done

while true; do
  echo Enter title \(for file name, default: \"${file_title}\"\)
  read line
  [[ ! -z "$line" ]] && file_title=$( echo ${line} | sed 's/[^a-zA-Z0-9]\+/-/g' | iconv -f utf8 -t ascii//TRANSLIT//IGNORE | tr [:upper:] [:lower:] )
  if [[ " ${existing_titles[@]} " =~ " ${file_title} " ]]; then  # check if it's already contained
    echo article with file title \"${file_title}\" already exists, choose another one
  else
    break
  fi
done

echo Enter author [default: "${DEFAULT_AUTHOR}"]:
read line
author=$DEFAULT_AUTHOR
[[ ! -z "$line" ]] && author=$line

categories=()
for filename in ../_category/*; do
  if [ -f "${filename}" ]; then
    fbname=$(basename "$filename" | cut -d. -f1)
    categories+=( ${fbname} )
  fi
done

i=0
echo Provide categories for the article:
for categorie in ${categories[@]}; do
  echo ${categorie} [${i}]
  (( i++ ))
done
echo finish [f]

article_categories=()
while true; do
  read entry
  if [ "$entry" == "f" ]; then
    if [ ${#article_categories} -eq 0 ]; then
      echo Article must belong to at least one category, add one:
    else
      article_categories=$(IFS=, ; echo "${article_categories[*]}")  # concatenate categories
      echo article categories: ${article_categories}
      break
    fi
  elif [[ "$entry" =~ ^[0-9]+$ ]]; then
    if [ "$(( entry ))" -ge 0 ] && [ "$(( entry ))" -lt ${#categories[@]} ]; then
      category_to_add=${categories[$(( entry ))]}
      if [[ " ${article_categories[@]} " =~ " ${category_to_add} " ]]; then  # check if it's already contained
        echo \"${category_to_add}\" already in article categories
      else
        article_categories+=( ${categories[$(( entry ))]} )
        echo category \"${category_to_add}\" added
      fi
    else
      echo invalid category number
    fi
  else
    echo invalid entry: must be \"f\" or an integer between 0 and $(( ${#categories[@]} - 1 ))
  fi
done

default_date=$(date +"%Y-%m-%d")
article_date=$default_date
while true; do
  echo Enter date \(default: ${default_date}\):
  read line
  if [ ! -z "$line" ]; then
    if date -d "$line" +"%Y-%m-%d" > /dev/null 2>&1; then
      article_date=$( date -d "$line" +"%Y-%m-%d" )
      break
    else
      echo invalid date format
    fi
  else
    break
  fi
done

while true; do
    read -p "Do you want to allow comments? (y/n, default: yes)" yn
    case $yn in
      "" ) allow_comments=true;break;;
      [Yy]* ) allow_comments=true;break;;
      [Nn]* ) allow_comments=false;break;;
      * ) echo "Please answer yes or no."
    esac
done

file_name=${article_date}-${file_title}.md

cd ../_posts/
touch ${file_name}
echo --- >> ${file_name}
echo layout: post >> ${file_name}
echo comments: ${allow_comments} >> ${file_name}
echo author: ${author} >> ${file_name}
echo title: ${article_title} >> ${file_name}
echo date: ${article_date} >> ${file_name}
echo categories: [${article_categories}] >> ${file_name}
echo --- >> ${file_name}
echo "" >> ${file_name}

echo article base created at ../_posts/${file_name}
