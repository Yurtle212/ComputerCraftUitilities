-- get latest version
shell.run("delete hiveminer.lua")
shell.run("wget https://raw.githubusercontent.com/Yurtle212/ComputerCraftUitilities/main/minecraft/turtles/hiveminer/hiveminer.lua")

shell.run("delete yurtle.lua")
shell.run("wget https://raw.githubusercontent.com/Yurtle212/ComputerCraftUitilities/main/minecraft/turtles/yurtle.lua")

shell.run("delete json")
shell.run("wget https://pastebin.com/raw/4nRg9CHU json")

-- run script
shell.run("hiveminer")