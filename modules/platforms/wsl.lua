-- WSL owns its environment-specific policy independently of Bob's desktop
-- configuration, which must never be assumed inside a Windows subsystem.
return { name = "wsl" }
