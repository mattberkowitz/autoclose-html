# autoclose-html package

Will automatically add closing tags when you complete the opening tag.

Install using

`apm install autoclose-html`

You need to check "Close on End of Opening Tag" in Atom > Preferences... > Autoclose Html to enable

Under normal circumstances ending tags will be inserted on the same line for inline elements and with \n\t\n in between for block elements. This is determined be attaching an element of the given type to the window and cehcking it's calculated `display` value.
You can use Force Inline and Force Block preferences to override this.
