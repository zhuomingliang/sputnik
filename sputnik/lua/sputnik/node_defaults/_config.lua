module(..., package.seeall)

NODE = {
   title="Configurations",
   category="_special_pages",
   prototype="@Lua_Config",
}

NODE.content = [=============[
-----------------------------------------------------------------------------
----------- THINGS YOU SHOULD PROBABLY CHANGE -------------------------------
-----------------------------------------------------------------------------

DOMAIN         = "www.freewisdom.org"       -- set this for RSS feeds to work properly
SITE_TITLE     = "My New Wiki"              -- change the title of the site
NICE_URL       = BASE_URL.."?p="            -- set if you want "nicer" URLs
HOME_PAGE      = "Home_Page"
HOME_PAGE_URL  = NICE_URL..HOME_PAGE        -- you could change this to get rid of "?p=HOME_PAGE"
COOKIE_NAME    = "Sputnik"                  -- change if you run several
SEARCH_PAGE    = "_search"                  -- comment out remove the search box
--SEARCH_CONTENT = "Installation"
SERVER_TZ      = "-05:00"                   -- set to the correct time zone offset for sitemap to work properly

--- change this to the URL of your logo
LOGO_URL    = "http://www.freewisdom.org/etc/sputnik.png"

------ variables that are defined in sputnik.lua but could be changed here --

--BASE_URL
--MARKUP_MODULE

-----------------------------------------------------------------------------
--------- other things you might want to change -----------------------------
-----------------------------------------------------------------------------

--- if you don't want your icons (RSS, etc.) served from freewisdom.org, put 
--- them somewhere else and put the URL here

ICONS_URL   = "http://media.freewisdom.org/etc/"

--- changes the language of the wiki interface

INTERFACE_LANGUAGE = "en"

NUM_HONEYPOTS_IN_FORMS = 5 -- set to a number > 0 to entertain the spammers

-----------------------------------------------------------------------------
----------- NOW WAIT FOR A SECOND -------------------------------------------
-----------------------------------------------------------------------------
--- PLEASE READ THE DOCUMENTATION BEFORE EDITING ANY OF THE PARAMETERS BELOW 
--- CHANGING THEM CAN MAKE THE SITE UNACCESSIBLE ----------------------------
-----------------------------------------------------------------------------

STYLESHEETS = { 
  NICE_URL.."_yui_reset.css",
  NICE_URL.."_layout.css",
  NICE_URL.."_colors.css",
}
DEFAULT_TEMPLATE_SET      = "_templates"
DEFAULT_NAVIGATION_BAR    = "_navigation"
TRANSLATIONS_PAGE         = "_translations"
HISTORY_PAGE              = "_history"
]=============]

