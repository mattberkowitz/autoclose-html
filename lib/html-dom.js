(function() {

	(function(editor) {
		var htmlGrammar;
		if(editor) {
			htmlGrammar = editor.displayBuffer.tokenizedBuffer.grammar.registry.grammarForScopeName('text.html.basic');
			htmlGrammar.rawPatterns.splice(7,0,{
				"match":"(</)([a-zA-z][a-zA-Z0-9:]*)[^><$]*(>)",
				"captures":  {
					"1": {
					"name": "punctuation.definition.tag.begin.html"
					},
					"2": {
						"name": "entity.name.tag.structure.any.html"
					},
					"3": {
					"name": "punctuation.definition.tag.end.html"
					}
				},
				"name":"meta.tag.structure.any.html.end"
			});
			htmlGrammar.rawPatterns.splice(7,0,{
				"match":"(<)([a-zA-z][a-zA-Z0-9:]*)[^><$]*(>)",
				"captures": {
					"1": {
						"name": "punctuation.definition.tag.begin.html"
					},
					"2": {
						"name": "entity.name.tag.structure.any.html"
					},
					"3": {
						"name": "punctuation.definition.tag.end.html"
					}
				},
				"name":"meta.tag.structure.any.html.start"
			});
			console.log(htmlGrammar);
		}
	})(atom.workspace.getActiveEditor());

	/*
	var HTMLRegex = {
		Element: /<([a-z][a-z0-9]+)[^><]*>/i,
		SelfClosingElement:/<([a-z][a-z0-9]+)[^><]* \/>/i,
		ElementClose: /<\/([a-z][a-z0-9]+)[^><]*>/i,
		UnfinishedElement: /<([a-z][a-z0-9]+)[<$]>/i,
		CommentStart: /<!-{2,}/,
		CommentEnd: /-{2,}>/,
		ScriptStart: /<script[^><]+>/i,
		ScriptEnd: /<\/script[^><]+>/i,
		StyleStart: /<script[^><]+>/i,
		StyleEnd: /<\/script[^><]+>/i
	};
	*/

	function fullParse (htmlDom)  {
		htmlDom.dom = new DocumnetFragment();
	}

	var HtmlDom = function(buffer) {
		this.buffer = buffer;
		fullParse(this);
	};

	return HtmlDom;
})();
