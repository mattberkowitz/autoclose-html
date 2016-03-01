isOpeningTagLikePattern = /<(?![\!\/])([a-z]{1}[^>\s=\'\"]*)[^>]*>$/i

ConfigSchema = require('./configuration.coffee')
{CompositeDisposable} = require 'atom'

module.exports =
    config: ConfigSchema.config

    neverClose:[]
    forceInline: []
    forceBlock: []
    makeNeverCloseSelfClosing: false
    ignoreGrammar: false
    legacyMode: false

    activate: () ->

        @autocloseHTMLEvents = new CompositeDisposable

        atom.commands.add 'atom-text-editor',
            'autoclose-html:close-and-complete': (e) =>
                if @legacyMode
                    console.log(e)
                    e.abortKeyBinding()
                else
                    atom.workspace.getActiveTextEditor().insertText(">")
                    this.execAutoclose()


        atom.config.observe 'autoclose-html.neverClose', (value) =>
            @neverClose = value

        atom.config.observe 'autoclose-html.forceInline', (value) =>
            @forceInline = value

        atom.config.observe 'autoclose-html.forceBlock', (value) =>
            @forceBlock = value

        atom.config.observe 'autoclose-html.makeNeverCloseSelfClosing', (value) =>
            @makeNeverCloseSelfClosing = value

        atom.config.observe 'autoclose-html.legacyMode', (value) =>
            @legacyMode = value
            if @legacyMode
                @_events()
            else
                @_unbindEvents()


    deactivate: ->
        if @legacyMode
            @_unbindEvents()

    isInline: (eleTag) ->
        if @forceInline.indexOf("*") > -1
            return true

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

    execAutoclose: () ->
        editor = atom.workspace.getActiveTextEditor()
        range = editor.selections[0].getBufferRange()
        line = editor.buffer.getLines()[range.end.row]
        partial = line.substr 0, range.start.column
        partial = partial.substr(partial.lastIndexOf('<'))

        return if partial.substr(partial.length - 1, 1) is '/'

        singleQuotes = partial.match(/\'/g)
        doubleQuotes = partial.match(/\"/g)
        oddSingleQuotes = singleQuotes && (singleQuotes.length % 2)
        oddDoubleQuotes = doubleQuotes && (doubleQuotes.length % 2)

        return if oddSingleQuotes or oddDoubleQuotes

        index = -1
        while((index = partial.indexOf('"')) isnt -1)
            partial = partial.slice(0, index) + partial.slice(partial.indexOf('"', index + 1) + 1)

        while((index = partial.indexOf("'")) isnt -1)
            partial = partial.slice(0, index) + partial.slice(partial.indexOf("'", index + 1) + 1)

        return if not (matches = partial.match(isOpeningTagLikePattern))?

        eleTag = matches[matches.length - 1]

        if @isNeverClosed(eleTag)
            if @makeNeverCloseSelfClosing
                tag = '/>'
                if partial.substr partial.length - 1, 1 isnt ' '
                    tag = ' ' + tag
                editor.backspace()
                editor.insertText tag
            return

        isInline = @isInline eleTag

        if not isInline
            editor.insertNewline()
            editor.insertNewline()
        editor.insertText('</' + eleTag + '>')
        if isInline
            editor.setCursorBufferPosition range.end
        else
            editor.autoIndentBufferRow range.end.row + 1
            editor.setCursorBufferPosition [range.end.row + 1, atom.workspace.getActivePaneItem().getTabText().length * atom.workspace.getActivePaneItem().indentationForBufferRow(range.end.row + 1)]

    _events: () ->
        atom.workspace.observeTextEditors (textEditor) =>
            textEditor.observeGrammar (grammar) =>
                textEditor.autocloseHTMLbufferEvent.dispose() if textEditor.autocloseHTMLbufferEvent?
                if atom.views.getView(textEditor).getAttribute('data-grammar').split(' ').indexOf('html') > -1
                     textEditor.autocloseHTMLbufferEvent = textEditor.buffer.onDidChange (e) =>
                         if e?.newText is '>' && textEditor == atom.workspace.getActiveTextEditor()
                             setTimeout =>
                                 @execAutoclose()
                     @autocloseHTMLEvents.add(textEditor.autocloseHTMLbufferEvent)

    _unbindEvents: () ->
        @autocloseHTMLEvents.dispose()
