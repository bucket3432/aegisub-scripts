std = "luajit+lua52"
globals = {
  "aegisub",
}
max_line_length = 132
max_string_line_length = false

files["macros/*.lua"] = {
  globals = {
    "script_name",
    "script_description",
    "script_author",
    "script_version",
    "script_namespace",
  },
}
