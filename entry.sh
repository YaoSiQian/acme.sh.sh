#!/usr/bin/env bash

# Script: ACME Certificate Management Automation
# Description: Automates the process of issuing and deploying SSL certificates using acme.sh
# Environment Variables:
#   DOMAINS - Certificate domain configurations
#   CA - Certificate Authority server
#   EMAIL - Account email address
#   NOTIFY - Notification hooks
#   NOTIFY_LEVEL - Notification level
#   NOTIFY_MODE - Notification mode
#   NOTIFY_SOURCE - Notification source

# Format for DOMAINS environment variable:
# ISSUE_METHOD:DOMAIN1,DOMAIN2/DEPLOY_HOOK;ISSUE_METHOD:DOMAIN3,DOMAIN4/DEPLOY_HOOK
# Example: dns_cf:example.com,*.example.com/deploy_cf;dns_ali:test.com/deploy_ali

# Helper function to expand comma-separated lists into command arguments
# Args:
#   $1: Comma-separated list of values
#   $2: Argument prefix (e.g., "-d" for domains)
# Returns: Space-separated arguments with prefix
expand_to_args() {
    local list=$(echo "$1" | tr ',' '\n')
    for item in $list; do
        echo " $2 $item"
    done
}

# Initialize Certificate Authority settings
init_ca() {
    [[ -n "$CA" ]] && --set-default-ca --server "$CA"
}

# Register ACME account with email
init_email() {
    if [ -z "$EMAIL" ]; then
        echo "ERROR: EMAIL environment variable is required"
        exit 1
    fi
    --register-account -m "$EMAIL"
}

# Configure notification settings
init_notify() {
    [[ -z "$NOTIFY" ]] && return 0
    
    local notify_hook=$(expand_to_args "$NOTIFY" "--notify-hook")
    local notify_args=""
    
    [[ -n "$NOTIFY_LEVEL" ]] && notify_args+=" --notify-level $NOTIFY_LEVEL"
    [[ -n "$NOTIFY_MODE" ]] && notify_args+=" --notify-mode $NOTIFY_MODE"
    [[ -n "$NOTIFY_SOURCE" ]] && notify_args+=" --notify-source $NOTIFY_SOURCE"
    
    --set-notify $notify_hook $notify_args
}

# Process domain configurations and issue certificates
init_domains() {
    [[ -z "$DOMAINS" ]] && return 0
    
    local domains=$(echo "$DOMAINS" | tr ';' '\n')
    for domain_config in $domains; do
        local issue_part=$(echo "$domain_config" | cut -d '/' -f 1)
        local deploy_hook=$(echo "$domain_config" | awk -F"/" '{print (NF>1)?$2:""}')
        
        local issue_method=$(echo "$issue_part" | cut -d ':' -f 1)
        local domain_list=$(echo "$issue_part" | cut -d ':' -f 2)
        local domain_args=$(expand_to_args "$domain_list" "-d")
        
        echo "Issuing certificate for $domain_list using $issue_method"
        --issue --dns "$issue_method" $domain_args
        
        [[ -n "$deploy_hook" ]] && --deploy $domain_args --deploy-hook "$deploy_hook"
    done
}

# Main execution logic
if [ "$1" = "daemon" ]; then
    init_ca
    init_email
    init_notify
    init_domains
    exec crond -n -s -m off
else
    exec -- "$@"
fi