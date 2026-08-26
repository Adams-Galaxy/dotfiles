local w = require("wombat")

-- SSH host identities are small managed fragments. The user's root config
-- retains local integrations such as OrbStack and includes this directory.
w.module.from(".")
w.install(".ssh/config.d/bob.conf")
