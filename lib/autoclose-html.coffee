isOpeningTagLikePattern = /<(?![\!\/])([a-z]{1}[^>\s=\'\"]*)[^>]*>$/i
tagPattern = /<\s*(\/)?\s*([:a-z_][-:.\w]*)(?:".*?"|'.*?'|[^"'>])*?(\/)?\s*>/ig
# referenced XML spec, but omitted non-ascii characters
# /<\s*(\/)?\s*([:A-Za-z_\xC0-\xD6\xD8-\xF6\xF8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][-:.\w\xB7\xC0-\xD6\xD8-\xF6\xF8-\u037D\u037F-\u1FFF\u200C-\u200D\u203F-\u2040\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]*)(?:".*?"|'.*?'|[^"'>\/])*(\/)?\s*>/g
# (\u{10000}-\u{EFFFF} are also valid characters, but I don't know how to use them in regex)

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
                    switch e.originalEvent.which
                        when 190    # > was entered
                            atom.workspace.getActiveTextEditor().insertText('>')
                            @execAutoclose(false)
                        when 191    # / was entered
                            atom.workspace.getActiveTextEditor().insertText('/')
                            @execAutoclose(true) if @getPreviousLetter(2) is '<'


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

    execAutoclose: (isTagClosing) ->
        editor = atom.workspace.getActiveTextEditor()
        position = editor.getCursorBufferPosition()

        if isTagClosing
            return false if position.column < 2
            partial = editor.getTextInBufferRange [[0, 0], [position.row, position.column - 2]]

            tags = []
            lcTags = []
            lastIndex = 0
            while((result = tagPattern.exec(partial)) isnt null)
                lastIndex = tagPattern.lastIndex
                continue if result[3] or @isNeverClosed(result[2])  # <tag/> or <br>, i.e.

                if not result[1]    # open tag
                    tags.push result[2]
                    lcTags.push result[2].toLowerCase()
                else                # close tag
                    index = lcTags.lastIndexOf result[2].toLowerCase()
                    if index > -1
                        tags = tags.slice 0, index
                        lcTags = lcTags.slice 0, index

            return false if not tags.length                         # no tags unclosed
            return false if partial.indexOf('<', lastIndex) > -1    # cursor is in the tag

            eleTag = tags.pop()
        else
            partial = editor.getTextInBufferRange [[position.row, 0], position]

            return false if partial.substr(partial.length - 1, 1) is '/'

            singleQuotes = partial.match(/\'/g)
            doubleQuotes = partial.match(/\"/g)
            oddSingleQuotes = singleQuotes && (singleQuotes.length % 2)
            oddDoubleQuotes = doubleQuotes && (doubleQuotes.length % 2)

            return false if oddSingleQuotes or oddDoubleQuotes

            index = -1
            while((index = partial.indexOf('"')) isnt -1)
                partial = partial.slice(0, index) + partial.slice(partial.indexOf('"', index + 1) + 1)

            while((index = partial.indexOf("'")) isnt -1)
                partial = partial.slice(0, index) + partial.slice(partial.indexOf("'", index + 1) + 1)

            return false if not (matches = partial.match(isOpeningTagLikePattern))?

            eleTag = matches[matches.length - 1]

            if @isNeverClosed(eleTag)
                if @makeNeverCloseSelfClosing
                    tag = '/>'
                    if partial.substr partial.length - 1, 1 isnt ' '
                        tag = ' ' + tag
                    editor.backspace()
                    editor.insertText tag
                return true

        isInline = @isInline eleTag

        if isTagClosing
            editor.insertText(eleTag + '>')

            if not isInline
                editor.insertNewline()
        else
            if not isInline
                editor.insertNewline()
                editor.insertNewline()
                editor.autoIndentBufferRow position.row + 1

            editor.insertText('</' + eleTag + '>')

            if isInline
                editor.setCursorBufferPosition position
            else
                editor.setCursorBufferPosition [position.row + 1, atom.workspace.getActivePaneItem().getTabText().length * atom.workspace.getActivePaneItem().indentationForBufferRow(position.row + 1)]

        true

    getPreviousLetter: (offset) ->
        editor = atom.workspace.getActiveTextEditor()
        position = editor.getCursorBufferPosition()

        return '' if position.column < offset
        editor.getTextInBufferRange([[position.row, position.column - offset], [position.row, position.column - offset + 1]])

    _events: () ->
        atom.workspace.observeTextEditors (textEditor) =>
            textEditor.observeGrammar (grammar) =>
                textEditor.autocloseHTMLbufferEvent.dispose() if textEditor.autocloseHTMLbufferEvent?
                if atom.views.getView(textEditor).getAttribute('data-grammar').split(' ').indexOf('html') > -1
                    textEditor.autocloseHTMLbufferEvent = textEditor.buffer.onDidChange (e) =>
                        if textEditor == atom.workspace.getActiveTextEditor()
                            switch e?.newText
                                when '>'
                                    setTimeout =>
                                        @execAutoclose(false)
                                when '/'
                                    break if @getPreviousLetter(2) isnt '<'
                                    setTimeout =>
                                        @execAutoclose(true)
                    @autocloseHTMLEvents.add(textEditor.autocloseHTMLbufferEvent)

    _unbindEvents: () ->
        @autocloseHTMLEvents.dispose()
