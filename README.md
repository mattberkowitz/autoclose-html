# Auto Close HTML package for Atom Text Editor

Will automatically add closing tags when you complete the opening tag.

Install using

`apm install autoclose-html`

Under normal circumstances ending tags will be inserted on the same line for inline elements and with `\n\t\n` in between for block elements. This is determined by attaching an element of the given type to the window and checking it's calculated `display` value.
You can use Force Inline and Force Block preferences to override this.

By Default works for HTML, HTML (Go), HTML (Rails), HTML (Angular), HTML (Mustache), HTML (Handlebars), HTML (Ruby - ERB), PHP

0.7.0 Note: Removed the option to enable/disable auto closing. Just disable/remove the plugin to stop.

# Options

## Additional Grammar

Comma delimited list of grammar names, other than defauts (see above), to apply this plugin to. Use "*" to run for all grammars.

## Force Inline

Elements in this comma delimited list will render their closing tags on the same line, even if they are block by default.

## Force Block

Elements in this comma delimited list will render their closing tags after a tabbed line, even if they are inline by default. If for some reason you think you're being tricky and put an element in both Force Inline and Force Block, block will override inline.

## Never Close

Elements in this comma delimited list should *not* render a closing tag

## Make Never Close Elements Self Closing

Will convert elements in Never Close list from `<br>` to `<br />`

## ~~Ignore Grammar~~

~~Under normal circumstances this package will only run in editors with HTML set as the grammar. If you would like to force it to run else where, check this.  Please note templating languages which use `<` and `>` for things other than HTML will likely trigger false-positives/be annoying.~~
This option was removed in 0.9.0, if you had it checked prior to that Additional Grammars will be set to "*" on load

## Always Inline

If this option is selected, all closing tags will be rendered on the same line.

# TODO
* Add option to autocomplete after `</` of closing tag. (requires parsing of whole document to figure out what the open element is)
