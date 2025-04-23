project = "bucket3432's Aegisub Scripts"
title = project
full_description = "A collection of scripts for Aegisub by bucket3432."
format = "markdown"
file = {
  "macros",
  "modules",
}
template = ".ldoc"
dir = "docs"
style = "!pale"
topics = {
  "README.md",
  "LICENSE",
}
new_type("menuitem", "Menu items")
alias("macro", "script") -- using new_type doesn't work because new types cannot be marked as code types
kind_names = {
  script = "Macros",
}
vars = {
  typename = function (modtype)
    return ({
      script = "Macro",
    })[modtype:lower()] or modtype
  end,
  github = "https://github.com/bucket3432/aegisub-scripts",
}
custom_tags = {
  {"displayname", hidden = true},
}
custom_display_name_handler = function(item, default_handler)
  if item.tags.displayname then
    return item.tags.displayname[1]
  else
    return default_handler(item)
  end
end
