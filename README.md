# Silo
Computercraft Expandable Item Inventory
~~~
Usage: silo                  -- view all items in storage
       silo get <item> [#]   -- get [#] items from storage with <item> in item's name
       silo search <item>    -- view all items with <item> in item's name
       silo dump             -- dump/store items from dump chest into storage
       silo info             -- shows (number of items/slots used) / (total available)
~~~


#### Install:
1) place computer or advanced computer
3) place minecraft chests
4) connect computer to chests by using wired modems and networking cables
5) right click the modems to connect the computer/chests to network
6) enter the following in the computer
~~~
For Classic Version:
wget https://raw.githubusercontent.com/GuitarMusashi616/Silo/master/silo.lua

For UI Version:
wget https://raw.githubusercontent.com/GuitarMusashi616/Silo/master/ui.lua
~~~
7) choose a dump chest and pickup chest, edit DUMP_CHEST_NAME and PICKUP_CHEST_NAME in the silo.lua file so that they have the correct chest name at the right of their respective equals sign (chest name is displayed when right clicking modem next to the chest) (run "edit silo" to edit file)
8) all done, now the above commands should work


### New UI Version
~~~
Usage: ui       -- silo program with clean user interface
       ui help  -- instructions will be printed
~~~
1) type to search for items
2) press 1-9 to get that item
3) press tab to clear dump/pickup chest
4) press grave to clear search

#### Required Mods:
cc-tweaked-1.16.5-1.98.1.jar
