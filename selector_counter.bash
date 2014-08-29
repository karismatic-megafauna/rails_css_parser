#!/bin/bash

shopt -s expand_aliases
alias cssgrep='grep --include=*.{css,scss,css.erb} -r '

COUNT=3
SEARCHPATH=.
COUNTSFILE=".sel_count.counts.$(date +%N).tmp"
MATCHESFILE=".sel_count.matches.$(date +%N).tmp"
RESULTSFILE="selector_counter.results.txt"

function usage
{
    echo "Usage: selector_counter [COUNT] [SEARCHPATH]"
    echo "Finds style declarations with COUNT or more levels of selectors in SEARCHPATH"
    echo -e "\n    - COUNT defaults to 3"
    echo -e "\n    - SEARCHPATH defaults to the current working directory\n"
    exit
}

function setUpVariables
{
    [ "$1" = "help" ] && usage

    [ "$1" != "" ] && COUNT="$1"
    [ "$2" != "" ] && SEARCHPATH="$2"

    [ "$COUNT" = "" ] && usage
    [ "$SEARCHPATH" = "" ] && usage
    
    REGSTRING="\([^ ,]\{2,\}\ \)\{${COUNT},\}.*{$"
}

function recordCountsAndMatches
{
    cssgrep -ce "$REGSTRING" $SEARCHPATH | grep -ve "\:0$" | sed -e 's/\:\([0-9]*\)$/ (\1 instances)/' > $COUNTSFILE
    cssgrep -ne "$REGSTRING" $SEARCHPATH > $MATCHESFILE
}

function aggregateResults
{
    echo > $RESULTSFILE
    
    cat $COUNTSFILE | while read line; do
        local just_file=$(echo $line | sed -e "s/[ ](.*$//")
        echo -e "\e[1;36m${line}\e[0m" | tee -a $RESULTSFILE
        echo -e "$(grep $just_file $MATCHESFILE | sed -e "s/^.*\:\([0-9]*\:\)\(.*$\)/  \\\e[0;32m\1\\\e[0m \\\e[1;31m\2\\\e[0m/")" | tee -a $RESULTSFILE
    done
}

function summarize
{
    echo -e "\nFound \e[1;31m$(wc -l < $MATCHESFILE)\e[0m instance(s) of styles with \e[1;33m$COUNT\e[0m or more levels of selectors in \e[1;36m$(wc -l < $COUNTSFILE)\e[0m file(s).\n" | tee -a $RESULTSFILE
    echo -e "Results written to \e[30;47m$RESULTSFILE\e[0m"
}

function cleanUp
{
    rm $COUNTSFILE $MATCHESFILE
    unalias cssgrep
}

setUpVariables "$1" "$2"
recordCountsAndMatches
aggregateResults
summarize
cleanUp

exit 0
