isOpeningTagLikePattern = /<(?![\!\/])([a-z]{1}[^>\s=\'\"]*)[^>]*$/i
defaultGrammars = ['HTML', 'HTML (Go)', 'HTML (Rails)', 'HTML (Mustache)', 'HTML (Ruby - ERB)', 'PHP']

ConfigSchema = require('./configuration.coffee')

ConfigSchema.migrate(atom.config)

module.exports =
    config: ConfigSchema.config

    neverClose:[]
    forceInline: []
    forceBlock: []
    grammars: defaultGrammars
    makeNeverCloseSelfClosing: false
    ignoreGrammar: false

    activate: () ->

        atom.config.observe 'autoclose-html.neverClose', (value) =>
            @neverClose = value

        atom.config.observe 'autoclose-html.forceInline', (value) =>
            @forceInline = value

        atom.config.observe 'autoclose-html.forceBlock', (value) =>
            @forceBlock = value

        atom.config.observe 'autoclose-html.additionalGrammars', (value) =>
            if '*' in value
                @ignoreGrammar = true
            else
                @grammars = defaultGrammars.concat(value)

        atom.config.observe 'autoclose-html.makeNeverCloseSelfClosing', (value) =>
            @makeNeverCloseSelfClosing = value

        @_events()

    isInline: (eleTag) ->
        try
            ele = document.createElement eleTag
        catch
            return false

        if eleTag.toLowerCase() in @forceBlock
            return false
        else if eleTag.toLowerCase() in @forceInline
            return true

        document.body.appendChild ele
        ret = window.getComputedStyle(ele).getPropertyValue('display') in ['inline', 'inline-block', 'none']
        document.body.removeChild ele

        ret

    isNeverClosed: (eleTag) ->
        eleTag.toLowerCase() in @neverClose

    execAutoclose: (changedEvent, editor) ->
        if changedEvent?.newText is '>' && editor == atom.workspace.getActiveTextEditor()
            line = editor.buffer.getLines()[changedEvent.newRange.end.row]
            partial = line.substr 0, changedEvent.newRange.start.column

            return if partial.substr(partial.length - 1, 1) is '/'

            return if not (matches = partial.substr(partial.lastIndexOf('<')).match isOpeningTagLikePattern)?

            eleTag = matches[matches.length - 1]

            if @isNeverClosed(eleTag)
                if @makeNeverCloseSelfClosing
                    setTimeout ->
                        tag = '/>'
                        if partial.substr partial.length - 1, 1 isnt ' '
                            tag = ' ' + tag
                        editor.backspace()
                        editor.insertText tag
                return

            isInline = @isInline eleTag

            setTimeout ->
                if not isInline
                    editor.insertNewline()
                    editor.insertNewline()
                editor.insertText('</' + eleTag + '>')
                if isInline
                    editor.setCursorBufferPosition changedEvent.newRange.end
                else
                    editor.autoIndentBufferRow changedEvent.newRange.end.row + 1
                    editor.setCursorBufferPosition [changedEvent.newRange.end.row + 1, atom.workspace.getActivePaneItem().getTabText().length * atom.workspace.getActivePaneItem().indentationForBufferRow(changedEvent.newRange.end.row + 1)]

    _events: () ->
        atom.workspace.observeTextEditors (textEditor) =>
            bufferEvent = null
            textEditor.observeGrammar (grammar) =>
                bufferEvent.dispose() if bufferEvent?
                if grammar.name?.length > 0 and (@ignoreGrammar or grammar.name in @grammars)
                    bufferEvent = textEditor.buffer.onDidChange (e) =>
                        @execAutoclose e, textEditor
