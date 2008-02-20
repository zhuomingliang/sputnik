module(..., package.seeall)

NODE = {
   title="@Lua_Config (Prototype for Lua Config Files)",
   fields = [[content.activate = "lua"]],
   permissions = [[
      deny(all, "save")
      allow("Admin", "save")
   ]],
   category="_prototypes",
   actions=[[show_content="wiki.show_content_as_lua_code"]],
}
NODE.content=[===[
--The content of this page is ignored but it's fields are inherited by 
--some of the other pages of this wiki.
]===]