-- Token moderation
-- this module looks for a field on incoming JWT tokens called "moderator". 
-- If it is true the user is added to the room as a moderator, otherwise they are set to a normal user.
-- Note this may well break other affiliation based features like banning or login-based admins
local log = module._log;
local jid_bare = require "util.jid".bare;
local json = require "cjson";
local basexx = require "basexx";
local um_is_admin = require "core.usermanager".is_admin;

local function is_admin(jid)
        return um_is_admin(jid, module.host);
end

log('info', 'Loaded token moderation plugin');
-- Hook into room creation to add this wrapper to every new room
module:hook("muc-room-created", function(event)
        log('info', 'room created, adding token moderation code');
        local room = event.room;
        local _handle_normal_presence = room.handle_normal_presence;
        local _handle_first_presence = room.handle_first_presence;
        -- Wrap presence handlers to set affiliations from token whenever a user joins
        room.handle_normal_presence = function(thisRoom, origin, stanza)
                local pres = _handle_normal_presence(thisRoom, origin, stanza);
                setupAffiliation(thisRoom, origin, stanza);
                return pres;
        end;
        room.handle_first_presence = function(thisRoom, origin, stanza)
                local pres = _handle_first_presence(thisRoom, origin, stanza);
                setupAffiliation(thisRoom, origin, stanza);
                return pres;
        end;
        -- Wrap set affilaition to block anything but token setting owner (stop pesky auto-ownering)
        local _set_affiliation = room.set_affiliation;
        room.set_affiliation = function(room, actor, jid, affiliation, reason)
                -- let this plugin do whatever it wants
                if actor == "token_plugin" then
                        return _set_affiliation(room, true, jid, affiliation, reason);
                -- noone else can assign owner (in order to block prosody/jisti's built in moderation functionality
                elseif affiliation == "owner" then
                        return _set_affiliation(room, true, jid, nil, "not-acceptable");
                -- keep other affil stuff working as normal (hopefully, haven't needed to use/test any of it)
                else
                        return _set_affiliation(room, actor, jid, affiliation, reason);
                end;
        end;
end);
function setupAffiliation(room, origin, stanza)
        if origin.auth_token then
                -- Extract token body and decode it
                local dotFirst = origin.auth_token:find("%.");
                if dotFirst then
                        local dotSecond = origin.auth_token:sub(dotFirst + 1):find("%.");
                        if dotSecond then
                                local bodyB64 = origin.auth_token:sub(dotFirst + 1, dotFirst + dotSecond - 1);
                                local body = json.decode(basexx.from_url64(bodyB64));
                                local jid = jid_bare(stanza.attr.from);
                                -- If user is a moderator or an admin, set their affiliation to be an owner
                                if body["moderator"] == true or is_admin(jid) then
                                        room:set_affiliation("token_plugin", jid, "owner");
                                else
                                        room:set_affiliation("token_plugin", jid, "member");
                                end;
			end;
		end;
	end;
end;
