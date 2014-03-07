(function() {


    module.exports = {
        active: false,
        forceInline: [],
        forceBlock: [],
        configDefaults: {
            closeOnEndOfOpeningTag: false,
            forceInline: 'title, h1, h2, h3, h4, h5, h6',
            forceBlock: ''
        },
        activate: function() {
            var self = this;

            //atom.workspaceView.command("autoclose-html:toggle", (function(__this) { return __this.toggle(); })(this));
            atom.config.observe('autoclose-html.closeOnEndOfOpeningTag', {callNow:true}, function(value) {
                self.toggleAutoclose(value);
            });

            atom.config.observe('autoclose-html.forceInline', {callNow:true}, function(value) {
                self.forceInline = value.split(/\s*[\s,|]+\s*/g);
            });

            atom.config.observe('autoclose-html.forceBlock', {callNow:true}, function(value) {
                self.forceBlock = value.split(/\s*[\s,|]+\s*/g);
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

            return (display === 'inline' || display === 'inline-block');
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
                        if(grammar.name === 'HTML') {
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
