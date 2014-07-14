
concatPattern = /\s*[\s,|]+\s*/g
tagPattern = /<([a-z]{1}[^>\s]*)/g

module.exports =

    autocloseActive: false
    neverClose:[]
    forceInline: []
    forceBlock: []
    makeNeverCLoseSelClosing: false
    ignoreGrammar: false
    configDefaults:

        closeOnEndOfOpeningTag: false
        neverClose: 'br, hr, img, input, link, meta, area, base, col, command, embed, keygen, param, source, track, wbr'
        makeNeverCloseElementsSelfClosing: false
        forceInline: 'title, h1, h2, h3, h4, h5, h6'
        forceBlock: ''
        ignoreGrammar: false

    activate: () ->

        atom.config.observe 'autoclose-html.closeOnEndOfOpeningTag', callNow:true, (value) =>
            @autocloseActive = value

        atom.config.observe 'autoclose-html.neverClose', callNow:true, (value) =>
            @neverClose = value.split(concatPattern)

        atom.config.observe 'autoclose-html.forceInline', callNow:true, (value) =>
            @forceInline = value.split(concatPattern)

        atom.config.observe 'autoclose-html.forceBlock', callNow:true, (value) =>
            @forceBlock = value.split(concatPattern)

        atom.config.observe 'autoclose-html.makeNeverCloseElementsSelfClosing', {callNow:true}, (value) =>
            @makeNeverCloseSelfClosing = value

        atom.config.observe 'autoclose-html.ignoreGrammar', callNow:true, (value) =>
            @ignoreGrammar = value

        @_events()

    isInline: (eleTag) ->
        ele = document.createElement eleTag

        if eleTag.toLowerCase() in @forceBlock
            return false
        else if eleTag.toLowerCase() in @forceInline
            return true

        document.body.appendChild ele
        ret = window.getComputedStyle(ele).getPropertyValue('display') in ['inline', 'inline-block', 'none']
        document.body.appendChild ele

        ret

    isNeverClosed: (eleTag) ->
        eleTag.toLowerCase() in @neverClose

    execAutoclose: (changedEvent) ->
        if changedEvent.newText is '>'
            line = atom.workspaceView.getActiveView().editor.buffer.getLines()[changedEvent.newRange.end.row]
            partial = line.substr 0, changedEvent.newRange.start.column

            return if partial.substr(partial.length - 1, 1) is '/'

            matches = partial.match tagPattern

            return if not matches?

            eleTag = matches[matches.length - 1].substr 1
            if @isNeverClosed(eleTag)
                if @makeNeverCloseSelfClosing(eleTag)
                    setTimeout () ->
                        tag = '/>'
                        if partial.substr partial.length - 1, 1 isnt ' '
                            tag = ' ' + tag
                        atom.atom.workspace.activePaneItem.backspace()
                        atom.workspace.activePaneItem.insertText tag
                return

            isInline = @isInline eleTag

            setTimeout () ->
                if not isInline
                    atom.workspace.activePaneItem.insertNewline()
                    atom.workspace.activePaneItem.insertNewline()
                atom.workspace.activePaneItem.insertText('</' + eleTag + '>')
                if isInline
                    atom.workspace.activePaneItem.setCursorBufferPosition changedEvent.newRange.end
                else
                    atom.workspace.activePaneItem.autoIndentBufferRow changedEvent.newRange.end.row + 1
                    atom.workspace.activePaneItem.setCursorBufferPosition [changedEvent.newRange.end.row + 1, atom.workspace.activePaneItem.getTabText().length * atom.workspace.activePaneItem.indentationForBufferRow(changedEvent.newRange.end.row + 1)]

    _events: () ->

        fcn = (e) =>
            if @autocloseActive and e.newText is '>'
                @execAutoclose e

        atom.workspaceView.eachEditorView (editorView) =>
            editorView.command 'editor:grammar-changed', {}, () =>
                grammar = editorView.editor.getGrammar()
                if grammar.name?.length > 0 and (@ignoreGrammar or grammar.name is 'HTML')
                    editorView.editor.buffer.off 'changed', fcn
                    editorView.editor.buffer.on 'changed', fcn
                else
                    editorView.editor.buffer.off 'changed', fcn
            editorView.trigger 'editor:grammar-changed'
