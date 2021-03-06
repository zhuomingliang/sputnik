
module(..., package.seeall)

local sorttable = require"sputnik.javascript.sorttable"
local wiki = require("sputnik.actions.wiki")
local util = require("sputnik.util")

actions = {}

local function format_list(nodes, template, sputnik, node, request)
   return util.f(template){
            new_url = sputnik:make_url(node.id.."/new", "edit"),
            id      = node.id,
            content = node.content,
            format_time = function(params)
               return sputnik:format_time(unpack(params))
            end,
            make_link = function(params)
               return sputnik:make_link(unpack(params))
            end,
            do_nodes = function()
                          for i, node in ipairs(nodes) do
                             local t = {
                                url = sputnik.config.NICE_URL..node.id,
                                id  = node.id,
                                short_id = node.id:match("[^%/]*$"),
                                nice_url = sputnik.config.NICE_URL,
                             }
                             for k, v in pairs(node.fields) do
                                 t[k] = tostring(node[k])
                             end
                             cosmo.yield (t)
                          end
            end,
         }
end

function actions.show(node, request, sputnik)
   local node_hash, node_ids, num_hidden = node:get_visible_children(request.user or "Anonymous")
   local non_proto_nodes = {}
   for i, id in ipairs(node_ids) do
      n = node_hash[id]
      if n.id ~= node.id .. "/@Child" then
         table.insert(non_proto_nodes, n)
      end
   end

   local template = node.translator.translate(node.html_content)

   node:add_javascript_snippet(sorttable.script)

   local values = {
      new_id  = node.id .. "/new",
      new_url = sputnik:make_url(node.id.."/new", "edit"),
      id      = node.id,
      content = node.content,
      markup = function(params)
         return node.markup.transform(params[1], node)
      end,
      format_time = function(params)
         return sputnik:format_time(unpack(params))
      end,
      make_url = function(params)
         local id, action, _, anchor = unpack(params)
         for i=1,#params do
            params[i] = nil
         end
         return sputnik:make_url(id, action, params, anchor)
      end,
      has_node_permissions = function(params)
          local id, action = unpack(params)
          local node = sputnik:get_node(id)
          local has_permission = node:check_permissions(request.user, action)
          cosmo.yield{
              _template = has_permission and 1 or 2,
          }
      end,
      do_nodes = function()
         if type(node.sort_params) == "table" then
            local sparams = node.sort_params
            local skey = sparams.sort_key or "id"
            local sdesc = sparams.sort_desc
            local stype = sparams.sort_type

            -- Set up conversion functions
            local convert = function(x) return x end
            if stype == "number" then
               convert = tonumber
            elseif stype == "string" then
               convert = tostring
            end

            if sdesc then
               table.sort(non_proto_nodes, function(a, b)
                  return convert(b[skey]) < convert(a[skey])
               end)
            else
               table.sort(non_proto_nodes, function(a, b)
                  return convert(a[skey]) < convert(b[skey])
               end)
            end
         end
         for i, node in ipairs(non_proto_nodes) do
             sputnik:decorate_node(node)
            local t = {
               url = sputnik.config.NICE_URL..node.id,
               id  = node.id,
               short_id = node.id:match("[^%/]*$"),
               nice_url = sputnik.config.NICE_URL,
               logged_in_user = request.user,
            }
            for k, v in pairs(node.fields) do
               t[k] = tostring(node[k])
            end
            for action_name in pairs(node.actions) do
               if node:check_permissions(request.user, action_name) then
                  sputnik.logger:debug("Action: " .. tostring(action_name))
                  t[action_name .. "_link"] = sputnik:make_url(node.id, action_name)
                  t["if_user_can_" .. action_name] = cosmo.c(true){}
               else
                  t["if_user_can_" .. action_name] = cosmo.c(false){}
               end
            end
            cosmo.yield (t)
         end
      end,
   }

   for k,v in pairs(node.template_helpers or {}) do
      values[k] = v
   end

   for k,v in pairs(node.fields) do
      if not values[k] then
         values[k] = tostring(node[k])
      end
   end

   
   for action_name in pairs(node.actions) do
      if node:check_permissions(request.user, action_name) then
         sputnik.logger:debug("Action: " .. tostring(action_name))
         values[action_name .. "_link"] = sputnik:make_url(node.id, action_name)
         values["if_user_can_" .. action_name] = cosmo.c(true){}
      else
         values["if_user_can_" .. action_name] = cosmo.c(false){}
      end
   end

   node.inner_html = cosmo.fill(template, values)
   return node.wrappers.default(node, request, sputnik)
end

function actions.list_children_as_xml(node, request, sputnik)
   local nodes = wiki.get_visible_nodes(sputnik, request.user, node.id.."/")
   return format_list(nodes, node.xml_template, sputnik, node), "text/xml"
end

local PARENT_PATTERN = "(.+)%/[^%/]+$" -- everything up to the last slash

actions.edit_new_child = function(node, request, sputnik)
   local child_node = sputnik:get_node(node.id.."/__new")
   local child_proto = node.id .. "/@Child"
   if parent.child_proto and parent.child_proto:match("%S") then
      child_proto = parent.child_proto
   end
   sputnik:update_node_with_params(child_node,
                                   { prototype = child_proto,
                                     permissions ="allow(all_users, 'new_child')",
                                     title = "A new item",
                                     actions = 'save="collections.save_new"'
                                   })
   sputnik:activate_node(child_node)
   sputnik:decorate_node(child_node)
   return wiki.actions.edit(child_node, request, sputnik)
end

local function slug(title)
    return title:gsub("%s", "%_"):gsub("[^a-zA-Z0-9%-_]", "")
end

actions.save_new = function(node, request, sputnik)
   local parent_id = node.id:match(PARENT_PATTERN)
   local parent = sputnik:get_node(parent_id)
   local uid_format = "%06d"
   if parent.child_uid_format and parent.child_uid_format:match("%S") then
      uid_format = parent.child_uid_format
   end

   local uid = string.format(uid_format, sputnik:get_uid(parent_id))

   -- Support the string $slug in a uid_format to insert the slugged version
   -- of the node's title into the ending uid
   if uid:match("$slug") then
       uid = uid:gsub("$slug", tostring(slug(request.params.title)))
   end

   local new_id = string.format("%s/%s", parent_id, uid)
   local new_node = sputnik:get_node(new_id)
   local child_proto = node.id .. "/@Child"
   if parent.child_proto and parent.child_proto:match("%S") then
      child_proto = parent.child_proto
   end
   sputnik:update_node_with_params(new_node, {prototype = child_proto})
   new_node = sputnik:activate_node(new_node)

   request.params.actions = ""
   new_node.inner_html = "Created a new item: <a "..sputnik:make_link(new_id)..">"
                         ..new_id.."</a><br/>"
                         .."List <a "..sputnik:make_link(parent_id)..">items</a>"
   return wiki.actions.save(new_node, request, sputnik)
end

function actions.rss(node, request, sputnik)
   local title = "Recent Additions to '" .. node.title .."'"  --::LOCALIZE::--

   local items = wiki.get_visible_nodes(sputnik, request.user, node.id.."/")
   table.sort(items, function(x,y) return x.id > y.id end )

   local url_format = string.format("http://%s%%s", sputnik.config.DOMAIN)
   return cosmo.f(node.templates.RSS){  
      title   = title,
      baseurl = sputnik.config.BASE_URL, 
      channel_url = url_format:format(sputnik:make_url(node.id, request.action)),
      items   = function()
                   for i, item in ipairs(items) do
					   local node_info = sputnik.saci:get_node_info(item.id)
                       cosmo.yield{
                          link        = url_format:format(sputnik:make_url(item.id)),
                          title       = util.escape(item.title),
                          ispermalink = "false",
                          guid        = item.id,
                          author      = util.escape(node_info.author),
                          pub_date    = sputnik:format_time_RFC822(node_info.timestamp),
                          summary     = util.escape(item.content),
                       }
                   end
                end,
   }, "application/rss+xml"
end

