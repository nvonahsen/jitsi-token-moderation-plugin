FROM jitsi/prosody:latest

COPY "mod_token_moderation.lua" "/prosody-plugins-custom/"
