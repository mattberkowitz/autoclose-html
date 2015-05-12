module.exports =
    config:
        additionalGrammars:
            title: 'Additional Grammars'
            description: 'Comma delimited list of grammar names, other then HTML and PHP, to apply this plugin to. Use "*" to run for all grammers.'
            type: 'array'
            default: []
        forceInline:
            title: 'Force Inline'
            description: 'Elemnts in this comma delimited list will render their closing tag on the same line, even if they are default block'
            type: 'array'
            default: ['title', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6']
        forceBlock:
            title: 'Force Block'
            description: 'Elements in this comma delimited list will render their closing tags after a tabbed line, even if they are default inline'
            type: 'array'
            default: ['head']
        neverClose:
            title: 'Never Close Elements'
            description: 'Comma delimited list of elements to never close'
            type: 'array'
            default: ['br', 'hr', 'img', 'input', 'link', 'meta', 'area', 'base', 'col', 'command', 'embed', 'keygen', 'param', 'source', 'track', 'wbr']
        makNeverCloseeSelfClosing:
            title: 'Make Never Close Elements Self-Closing'
            description: 'Closes elements with " />" (ie <br> becomes <br />)'
            type: 'boolean'
            default: true
    migrate: (config) ->
        concatPattern = /\s*[,|]+\s*/g

        #convert ignoreGrammar to addtionalGramamrs = '*'
        if config.get('autoclose-html.ignoreGrammar') is true
            config.set 'autoclose-html.additionalGrammars', ['*']
            config.unset 'autoclose-html.ignoreGrammar'

        #convert additionalGrammars string to array
        if typeof config.get('autoclose-html.additionalGrammars') is 'string'
            config.set 'autoclose-html.additionalGrammars', config.get('autoclose-html.additionalGrammars').split(concatPattern)

        #convert forceInline string to array
        if typeof config.get('autoclose-html.forceInline') is 'string'
            config.set 'autoclose-html.forceInline', config.get('autoclose-html.forceInline').split(concatPattern)

        #convert forceBlock string to array
        if typeof config.get('autoclose-html.forceBlock') is 'string'
            config.set 'autoclose-html.forceBlock', config.get('autoclose-html.forceBlock').split(concatPattern)

        if typeof config.get('autoclose-html.neverClose') is 'string'
            neverClose = config.get('autoclose-html.neverClose')
            config.set('autoclose-html.neverClose', neverClose.split(concatPattern))
