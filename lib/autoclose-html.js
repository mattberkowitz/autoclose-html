(function() {

    var concatPattern = /\s*[\s,|]+\s*/g;

    module.exports = {
        active: false,
        neverClose: [],
        forceInline: [],
        forceBlock: [],
        makeNeverCloseSelfClosing: false,
        ignoreGrammar: false,
        configDefaults: {
            closeOnEndOfOpeningTag: false,
            neverClose: 'br, hr, img, input, link, meta, area, base, col, command, embed, keygen, param, source, track, wbr',
            makeNeverCloseElementsSelfClosing: false,
            forceInline: 'title, h1, h2, h3, h4, h5, h6',
            forceBlock: '',
            ignoreGrammar: false
        },
        activate: function() {
            var self = this;

            //atom.workspaceView.command("autoclose-html:toggle", (function(__this) { return __this.toggle(); })(this));
            atom.config.observe('autoclose-html.closeOnEndOfOpeningTag', {callNow:true}, function(value) {
                self.toggleAutoclose(value);
            });

            atom.config.observe('autoclose-html.neverClose', {callNow:true}, function(value) {
                self.neverClose = value.split(concatPattern);
            });

            atom.config.observe('autoclose-html.forceInline', {callNow:true}, function(value) {
                self.forceInline = value.split(concatPattern);
            });

            atom.config.observe('autoclose-html.forceBlock', {callNow:true}, function(value) {
                self.forceBlock = value.split(concatPattern);
            });

            atom.config.observe('autoclose-html.makeNeverCloseElementsSelfClosing', {callNow:true}, function(value) {
                self.makeNeverCloseSelfClosing = value;
            });

            atom.config.observe('autoclose-html.ignoreGrammar', {callNow:true}, function(value) {
                self.ignoreGrammar = value;
            });
        },
        isInline: function(eleTag) {
            var ele = document.createElement(eleTag),
            display,
            containsInsensitive = function(f) { return f.toLowerCase() === eleTag.toLowerCase(); };


            if(this.forceBlock.some(containsInsensitive)) {
                return false;
            } else if(this.forceInline.some(containsInsensitive)) {
                return true;
            }

            document.body.appendChild(ele);
            display = window.getComputedStyle(ele).getPropertyValue('display');
            document.body.removeChild(ele);

            return (display === 'inline' || display === 'inline-block' || display === 'none');
        },
        isNeverClosed: function(eleTag) {
            var lowerTag = eleTag.toLowerCase(),
            containsInsensitive = function(f) { return f.toLowerCase() === lowerTag; };
            return !!this.neverClose.some(containsInsensitive);
        },
        execAutoclose: function(changedEvent) {
            var line,
            partial,
            matches, eleTag, isInline,
            self = this;
            if(changedEvent.newText === '>') {

                line = atom.workspaceView.getActiveView().editor.buffer.getLines()[changedEvent.newRange.end.row];
                partial = line.substr(0, changedEvent.newRange.start.column);

                if(partial.substr(partial.length - 1, 1) === '/') {
                    return; //is self closing
                }

                matches = partial.match(/<(?![\!\/])([^>\s]+)/g);

                if(!matches) {
                    return; //not a match :(
                }

                eleTag = matches[matches.length - 1].substr(1);
                if (self.isNeverClosed(eleTag)) {
                    if(self.makeNeverCloseSelfClosing) {
                        setTimeout(function() {
                            var tag = '/>';
                            if(partial.substr(partial.length - 1, 1) !== ' ') {
                                tag = ' ' + tag;
                            }
                            atom.workspace.activePaneItem.backspace();
                            atom.workspace.activePaneItem.insertText(tag);
                        });
                    }
                    return;
                }
                isInline = self.isInline(eleTag);

                //calling this directly in the 'changed' event was fucking up the cursor...
                setTimeout(function() {
                    if(!isInline) {
                        atom.workspace.activePaneItem.insertNewline();
                        atom.workspace.activePaneItem.insertNewline();
                    }
                    atom.workspace.activePaneItem.insertText('</' + eleTag + '>');
                    if(isInline) {
                        atom.workspace.activePaneItem.setCursorBufferPosition(changedEvent.newRange.end);
                    } else {
                        atom.workspace.activePaneItem.autoIndentBufferRow(changedEvent.newRange.end.row + 1);
                        atom.workspace.activePaneItem.setCursorBufferPosition([changedEvent.newRange.end.row + 1, atom.workspace.activePaneItem.getTabText().length * atom.workspace.activePaneItem.indentationForBufferRow(changedEvent.newRange.end.row + 1)]);
                    }
                }, 10);
            }
        },
        toggleAutoclose: function(activate) {
            //This assumes the active pane item is an editor
            var self = this,
            fcn = (function(__this) {
                return function(e) {
                    return __this.execAutoclose(e);
                };
            }) (this);


            this.active = !this.active;
            if(activate === true) {
                this.active = true;
            } else if(activate === false) {
                this.active = false;
            }

            if(this.active) {

                atom.workspaceView.eachEditorView(function(editorView){
                    editorView.command('editor:grammar-changed', {}, function() {
                        var grammar = editorView.editor.getGrammar();
                        if(grammar.name && grammar.name.length > 0 && (self.ignoreGrammar || grammar.name === 'HTML')) {
                            editorView.editor.buffer.off('changed',fcn);
                            editorView.editor.buffer.on('changed', fcn);
                        } else {
                            editorView.editor.buffer.off('changed', fcn);
                        }
                    }).trigger('editor:grammar-changed');
                });

            } else {

                atom.workspace.eachEditor(function(editor){
                    editor.buffer.off('changed', fcn);
                });

            }
        }
    };



})();
