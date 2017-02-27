SFTP Server
===========


# Running

Just use this command to start the container.

```docker run --name sftp -v <host>:/data/incoming -d -P writl/sftp```

# Persistent Pubkeys

If you want to store the keys (so your fingerprint doesn't change) persistent, you can run it like that:

```docker run --name sftp -v <host>:/data/incoming -v <host>:/ssh -d -P writl/sftp```

# Configuration
These options can be set: (hint: it is even possible to use '33' as gid/uid)

- **USER**: Sets the username. (Default: "sftp", Possible Values: "<string>")
- **PASS**: Sets the password of the User (Default: "c83eDteUDT", Possible Values: "<string>")
- **GROUP_ID**: Sets GID of the user (Default: "1000", Possible Values: "<integer>")
- **USER_ID**: Sets UID of the user (Default: "1000", Possible Values: "<integer>")
- **PUBKEY**: Sets PUBKEY of the user (Possible Values: "<string>")
