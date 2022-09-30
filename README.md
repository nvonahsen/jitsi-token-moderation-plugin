# jitsi-token-moderation-plugin
Lua plugin for jitsi which determines whether users are moderator or not based on token contents

Note im just sharing this because I needed it for a project and it thought it might help people out there, but im not looking to maintain it or make improvements or anything so I probably wont be help much with any problems you might have. 

On the other hand, if you make any improvements to this and want to share feel free to make a pull request.

## Caveats
There's probably plenty of possible improvement as this is my first look at lua/prosody, i've tested it a bit but haven't tried many edge cases and only tried with my configuration

I'm not sure of how well it will work in 1 on 1 chats since I think prosody uses a different protocol for this by default, you can disable this option in the jitsi meet javascript config file though (search for p2p). 

This may well break may other features relying on prosody affiliations, such as: banning people, assigning roles within jitsi/prosody, using username/password login, and more. So try it with your setup and check whether it works.

## Installation
### Standalone
- Put the lua file somewhere on your jitsi server
- Open `/etc/prosody/conf.d/[YOUR DOMAIN].cfg.lua`
- At the very top of the file in **plugin_paths** after **"/usr/share/jitsi-meet/prosody-plugins/"** add `, "[DIRECTORY INTO WHICH YOU PUT THE MOD LUA]"`, like
```lua
plugin_paths = { "/usr/share/jitsi-meet/prosody-plugins/", "/usr/share/jitsi-meet/prosody-plugins-custom/" }
```
- Edit the `conferance.[YOUR DOMAIN]` component to add `token_moderation`
  - Change this line `modules_enabled = { [EXISTING MODULES] }` TO `modules_enabled = { [EXISTING MODULES]; "token_moderation"; }`, like
  ```lua
  Component "conference.meet.example.com" "muc"
    storage = "memory"
    modules_enabled = {
        "muc_meeting_id";
        "muc_domain_mapper";
        "token_verification";
        "token_moderation";
    }
    admins = { "focus@auth.meet.example.com" }
    muc_room_locking = false
    muc_room_default_public_jids = true
  ```
- Depending on your setup, you need to restart the services:
  - Run `sudo systemctl restart prosody && sudo systemctl restart jicofo && sudo systemctl restart jitsi-videobridge2` -- for ubuntu/debian systems that rely on `systemctl`
  - Run `prosodyctl restart && /etc/init.d/jicofo restart && /etc/init.d/jitsi-videobridge restart` in bash to restart prosody/jitsi/jicofo (note: running this on systems that rely on `systemctl` can cause permissions problems)
### Docker (based on the stack from [jitsi-meet](https://github.com/jitsi/docker-jitsi-meet))
- Set the ENV `XMPP_MUC_MODULES=token_moderation` for prosody at `.env` or `docker-compose.yml`.
- Add the file `mod_token_moderation.lua` to the image at `/prosody-plugins-custom`. You can use as an example the [Dockerfile](./Dockerfile) or you can mount the file directly into the container.

## Usage
Just include a boolean field "moderator" in the body of the jwt you create for jitsi, if its true that user will be mod, if not they wont. It works irrespective of which order people join in. 

Token body should look something like this:
```json
{
  "context": {
    "user": {
      "avatar": "https:/gravatar.com/avatar/abc123",
      "name": "John Doe",
      "email": "jdoe@example.com",
      "id": "abcd:a1b2c3-d4e5f6-0abc1-23de-abcdef01fedcba"
    },
    "group": "a123-123-456-789"
  },
  "aud": "*",
  "iss": "your_app_id",
  "sub": "meet.example.com",
  "room": "your_room",
  "moderator": true,
  "nbf": 1664475176,
  "exp": 1695998576
}
```
**More detail:** https://github.com/jitsi/lib-jitsi-meet/blob/master/doc/tokens.md#token-structure

**Important:** "moderator" is a **boolean** type and not a string! Therefore `true` and `false` should not be enclosed by `"` or `'`!

## License
MIT License

Copyright (c) 2019, Spark Sixty Four Ltd

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
