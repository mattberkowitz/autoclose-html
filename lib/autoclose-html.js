(function() {

    var HtmlDom;

    var concatPattern = /\s*[\s,|]+\s*/g;

    var tagRegex = /<(?!\!)(\/?[^>\s]+)[^>]*>/;

	function findTheOpener(lines, before) {
		var line, match, i=0, tag, tags = [];
		for(; i<lines.length; i++) {
			line = lines[i];

            if(i < lines.row) {
                while((match = line.match(tagRegex))) {

                    if(tag[0] === '/') {
                        tag = tag.substr(1);
                        if(tags[tags.length - 1] === tag) {
                            tags.pop();
                        }
                    } else {
                        tags.push(tag);
                    }

                }
            }
			if(i === before.row) {
				line = line.substr(0, before.column);
			}
			while((match = line.match(tagRegex))) {
				console.log(match);
				tag = match[1];
				if(tag[0] === '/') {
					tag = tag.substr(1);
					if(tags[tags.length - 1] === tag) {
						tags.pop();
					}
				} else {
                    tags.push(tag);
                }
				line = line.replace(tagRegex,'',1);
			}
		}
		return tags[tags.length - 1];
	}

    module.exports = {
        autocloseActive: false,
        autocompleteClosing: false,
        neverClose: [],
        forceInline: [],
        forceBlock: [],
        makeNeverCloseSelfClosing: false,
        configDefaults: {
            closeOnEndOfOpeningTag: false,
            neverClose: 'br, hr, img, input, link, meta, area, base, col, command, embed, keygen, param, source, track, wbr',
            makeNeverCloseElementsSelfClosing: false,
            forceInline: 'title, h1, h2, h3, h4, h5, h6',
            forceBlock: '',
            autoCompleteClosingTagsOnForwardSlash: false
        },
        activate: function() {

            var self = this;

            //atom.workspaceView.command("autoclose-html:toggle", (function(__this) { return __this.toggle(); })(this));
            atom.config.observe('autoclose-html.closeOnEndOfOpeningTag', {callNow:true}, function(value) {
                self.autocloseActive = value;
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

            atom.config.observe('autoclose-html.autoCompleteClosingTagsOnForwardSlash', {callNow:true}, function(value) {
                self.autocompleteClosing = value;
            });

            this._events();
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
            self = this,
            i = 0;
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
                    }, 10);
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

        },
        execAutocomplete: function(changedEvent) {

			var line, tag;

			line = atom.workspaceView.getActiveView().editor.buffer.getLines()[changedEvent.newRange.end.row];

			if(line.substr(changedEvent.newRange.start.column - 1, 1) === '<') {
				tag = findLastOpen(atom.workspaceView.getActiveView().editor.buffer.getLines(), changedEvent.newRange.end);
                if(tag) {
                    setTimeout(function() {
                        atom.workspace.activePaneItem.insertText(tag + '>');
                    }, 10);
                }
			}
        },
        runparser: function() {
            var htmlparser = require("htmlparser2");
            var lines = atom.workspaceView.getActiveView().editor.buffer.getLines();
            var handler = new htmlparser.DomHandler(function (error, dom) {
                if (error)
                    console.log(error);
                else
                    console.log(dom);
            });
            var parser = new htmlparser.Parser(handler);
            lines.forEach(function(line) {
                parser.write(line);
            });
            parser.done();
        },
        _events: function() {

            var self = this,
                fcn = function(e) {
                    if(self.autocloseActive && e.newText === '>') {
                        self.execAutoclose(e);
                    } else if (self.autocompleteClosing && e.newText === '/') {
                        self.execAutocomplete(e);
                    }
                };

            atom.workspaceView.eachEditorView(function(editorView){
                editorView.command('editor:grammar-changed', {}, function() {


                    var grammar = editorView.editor.getGrammar();
                    if(grammar.name === 'HTML') {


                        if(!HtmlDom) {
                            HtmlDom = require('./html-dom');
                        }

                        self.runparser();
                        editorView.editor.buffer.off('changed', fcn);
                        editorView.editor.buffer.on('changed', fcn);
                    } else {
                        editorView.editor.buffer.off('changed', fcn);
                    }
                }).trigger('editor:grammar-changed');
            });

        }
    };



})();
