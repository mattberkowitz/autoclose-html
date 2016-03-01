module.exports =
    config:
        forceInline:
            title: 'Force Inline'
            description: 'Elements in this comma delimited list will render their closing tags on the same line, even if they are block by default. Use * to force all closing tags to render inline'
            type: 'array'
            default: ['title', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6']
        forceBlock:
            title: 'Force Block'
            description: 'Elements in this comma delimited list will render their closing tags after a tabbed line, even if they are inline by default. Values are ignored if Force Inline is *'
            type: 'array'
            default: ['head']
        neverClose:
            title: 'Never Close Elements'
            description: 'Comma delimited list of elements to never close'
            type: 'array'
            default: ['br', 'hr', 'img', 'input', 'link', 'meta', 'area', 'base', 'col', 'command', 'embed', 'keygen', 'param', 'source', 'track', 'wbr']
        makeNeverCloseSelfClosing:
            title: 'Make Never Close Elements Self-Closing'
            description: 'Closes elements with " />" (ie &lt;br&gt; becomes &lt;br /&gt;)'
            type: 'boolean'
            default: true
        legacyMode:
            title: "Legacy/International Mode"
            description: "Do not use this unless you use a non-US or non-QUERTY keyboard and/or the plugin isn't working otherwise. USING THIS OPTION WILL OPT YOU OUT OF NEW IMPROVEMENTS/FEATURES POST 0.22.0"
            type: 'boolean'
            default: false
