#!/usr/bin/env sh

##########################################################################
# Hurricane Electric hook script for acme.sh
#
# Environment variables:
#
#  - $HE_DDNS_Key  (your challenge record's DDNS key)
#
# Note that this mode requires that you've already created the appropriate
# DDNS TXT record, and created/generated the DDNS key.
#
# This mode DOES NOT require your dns.he.net username or password, only the
# DDNS key for the specific TXT record.

#-- dns_he_ddns_add() - Add TXT record --------------------------------------
# Usage: dns_he_ddns_add _acme-challenge.subdomain.domain.com "XyZ123..."

dns_he_ddns_add() {
  _full_domain=$1
  _txt_value=$2
  _info "Using DNS-01 Hurricane Electric DDNS hook"

  _dns_he_ddns_update "$_full_domain" "$_txt_value"
}

#-- dns_he_ddns_rm() - Remove TXT record ------------------------------------
# Usage: dns_he_ddns_rm _acme-challenge.subdomain.domain.com "XyZ123..."

dns_he_ddns_rm() {
  _full_domain=$1
  _txt_value=$2
  _info "Cleaning up after DNS-01 Hurricane Electric DDNS hook"

  # set to something... bland
  _dns_he_ddns_update "$_full_domain" "NULL"
}

########################## PRIVATE FUNCTIONS ###########################

_dns_he_ddns_update() {
  _full_domain=$1
  _txt_value=$2

  HE_DDNS_Key="${HE_DDNS_Key:-$(_readaccountconf_mutable HE_DDNS_Key)}"
  if [ -z "$HE_DDNS_Key" ] ; then
    HE_DDNS_Key=
    _err "No auth details provided. Please set DDNS key using the \$HE_DDNS_Key environment variable."
    return 1
  fi
  _saveaccountconf_mutable HE_DDNS_Key "$HE_DDNS_Key"
  _debug HE_DDNS_Key "$HE_DDNS_Key"

  # strip the trailing '.'
  body="hostname=$(basename $_full_domain .)"
  body="$body&password=$HE_DDNS_Key"
  body="$body&txt=$_txt_value"
  _debug2 body "$body"

  response="$(_post "$body" https://dyn.dns.he.net/nic/update)"

  exit_code="$?"
  _debug2 exit_code "$exit_code"
  _debug2 response "$response"

  if _startswith "$response" "good" ; then
    _info "TXT record updated successfully."
    return 0
  elif _startswith "$response" "nochg" ; then
    _info "TXT record already set!"
    return 0
  elif _startswith "$response" "badauth"; then
    _err "dns.he.net says 'badauth' with the given DDNS key"
    return 1
  fi

  _err "Couldn't update the TXT record value: /$response/"
  return 1
}

# vim: et:ts=2:sw=2:
