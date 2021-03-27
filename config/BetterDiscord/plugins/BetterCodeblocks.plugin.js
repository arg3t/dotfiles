/**
 * @name BetterCodeblocks
 * @invite undefined
 * @authorLink undefined
 * @donate undefined
 * @patreon undefined
 * @website https://github.com/vBread/BetterCodeblocks
 * @source https://github.com/vBread/BetterCodeblocks/blob/master/BetterCodeblocks.plugin.js
 */
/*@cc_on
@if (@_jscript)
	
	// Offer to self-install for clueless users that try to run this directly.
	var shell = WScript.CreateObject("WScript.Shell");
	var fs = new ActiveXObject("Scripting.FileSystemObject");
	var pathPlugins = shell.ExpandEnvironmentStrings("%APPDATA%\BetterDiscord\plugins");
	var pathSelf = WScript.ScriptFullName;
	// Put the user at ease by addressing them in the first person
	shell.Popup("It looks like you've mistakenly tried to run me directly. \n(Don't do that!)", 0, "I'm a plugin for BetterDiscord", 0x30);
	if (fs.GetParentFolderName(pathSelf) === fs.GetAbsolutePathName(pathPlugins)) {
		shell.Popup("I'm in the correct folder already.", 0, "I'm already installed", 0x40);
	} else if (!fs.FolderExists(pathPlugins)) {
		shell.Popup("I can't find the BetterDiscord plugins folder.\nAre you sure it's even installed?", 0, "Can't install myself", 0x10);
	} else if (shell.Popup("Should I copy myself to BetterDiscord's plugins folder for you?", 0, "Do you need some help?", 0x34) === 6) {
		fs.CopyFile(pathSelf, fs.BuildPath(pathPlugins, fs.GetFileName(pathSelf)), true);
		// Show the user where to put plugins in the future
		shell.Exec("explorer " + pathPlugins);
		shell.Popup("I'm installed!", 0, "Successfully installed", 0x40);
	}
	WScript.Quit();

@else@*/

module.exports = (() => {
	const config = { "info": { "name": "BetterCodeblocks", "authors": [{ "name": "Bread", "discord_id": "304260051915374603" }], "version": "1.0.0", "description": "Enhances the look and feel of Discord's codeblocks with customizable colors", "github": "https://github.com/vBread/BetterCodeblocks", "github_raw": "https://github.com/vBread/BetterCodeblocks/blob/master/BetterCodeblocks.plugin.js" }, "changelog": [], "main": "index.js" };

	return !global.ZeresPluginLibrary ? class {
		constructor() { this._config = config; }
		getName() { return config.info.name; }
		getAuthor() { return config.info.authors.map(a => a.name).join(", "); }
		getDescription() { return config.info.description; }
		getVersion() { return config.info.version; }
		load() {
			BdApi.showConfirmationModal("Library Missing", `The library plugin needed for ${config.info.name} is missing. Please click Download Now to install it.`, {
				confirmText: "Download Now",
				cancelText: "Cancel",
				onConfirm: () => {
					require("request").get("https://rauenzi.github.io/BDPluginLibrary/release/0PluginLibrary.plugin.js", async (error, response, body) => {
						if (error) return require("electron").shell.openExternal("https://betterdiscord.net/ghdl?url=https://raw.githubusercontent.com/rauenzi/BDPluginLibrary/master/release/0PluginLibrary.plugin.js");
						await new Promise(r => require("fs").writeFile(require("path").join(BdApi.Plugins.folder, "0PluginLibrary.plugin.js"), body, r));
					});
				}
			});
		}
		start() {}
		stop() {}
	} : (([Plugin, Api]) => {
		const plugin = (Plugin, Library) => {
			const { Patcher, WebpackModules, DiscordModules, PluginUtilities, Settings } = Library;
			const { SettingPanel, SettingGroup, Textbox } = Settings
			const { React, hljs } = DiscordModules

			return class BetterCodeblocks extends Plugin {
				constructor() {
					super()

					this.defaults = {
						addition: '#98c379',
						attr_1: '#d19a66',
						attr_2: '#d19a66',
						attribute: '#98c379',
						background: '#282c34',
						built_in: '#e6c07b',
						bullet: '#61aeee',
						code: '#abb2bf',
						comment: '#5c6370',
						deletion: '#e06c75',
						doctag: '#c678dd',
						keyword: '#c678dd',
						literal: '#56b6c2',
						meta_string: '#98c379',
						meta: '#61aeee',
						name: '#e06c75',
						nomarkup: '#98c379',
						number: '#d19a66',
						params: '#abb2bf',
						quote: '#5c6370',
						regexp: '#98c379',
						section: '#e06c75',
						selector_attr: '#d19a66',
						selector_class: '#d19a66',
						selector_id: '#61aeee',
						selector_pseudo: '#d19a66',
						selector_tag: '#e06c75',
						string: '#98c379',
						subst: '#e06c75',
						symbol: '#61aeee',
						tag: '#e06c75',
						template_variable: '#d19a66',
						text: '#abb2bf',
						title: '#61aeee',
						type: '#d19a66',
						variable: '#d19a66'
					}

					this.hljs = PluginUtilities.loadSettings('BetterCodeblocks', this.defaults)
				}

				onStart() {
					const parser = WebpackModules.getByProps('parse', 'parseTopic')

					Patcher.after(parser.defaultRules.codeBlock, 'react', (_, args, res) => {
						this.inject(args, res)

						return res
					});

					PluginUtilities.addStyle('BetterCodeblocks', this.css)
				}

				onStop() {
					PluginUtilities.removeStyle('BetterCodeblocks')
					Patcher.unpatchAll();
				}

				getSettingsPanel() {
					return SettingPanel.build(PluginUtilities.saveSettings('BetterCodeblocks', this.hljs),
						new SettingGroup('Customization').append(
							new Textbox('Additions', 'Changes the color of additions for Diff', this.hljs.addition, (color) => this.updateColor('addition', color)),
							new Textbox('Annotation Tags', 'Changes the color of documentation/annotation tags', this.hljs.doctag, (color) => this.updateColor('doctag', color)),
							new Textbox('Attributes', 'Changes the color of HTML tag attributes', this.hljs.attribute, (color) => this.updateColor('attribute', color)),
							new Textbox('Background', 'Changes the color of the codeblock background', this.hljs.background, (color) => this.updateColor('background', color)),
							new Textbox('Built-In', 'Changes the color of built-in keywords', this.hljs.built_in, (color) => this.updateColor('built_in', color)),
							new Textbox('Bullets', 'Changes the color of bullet points for Markdown', this.hljs.bullet, (color) => this.updateColor('bullet', color)),
							new Textbox('Comments', 'Changes the color of comments', this.hljs.comment, (color) => this.updateColor('comment', color)),
							new Textbox('Deletions', 'Changes the color of deletions for Diff', this.hljs.deletion, (color) => this.updateColor('deletion', color)),
							new Textbox('Keywords', 'Changes the color of keywords', this.hljs.keyword, (color) => this.updateColor('keyword', color)),
							new Textbox('Literals', 'Changes the color of literal keywords', this.hljs.literal, (color) => this.updateColor('literal', color)),
							new Textbox('Names', 'Changes the color of function names', this.hljs.title, (color) => this.updateColor('title', color)),
							new Textbox('Number', 'Changes the color of numbers', this.hljs.number, (color) => this.updateColor('number', color)),
							new Textbox('Parameters', 'Changes the color of function parameters', this.hljs.params, (color) => this.updateColor('params', color)),
							new Textbox('Regular Expressions', 'Changes the color of regular expressions', this.hljs.regexp, (color) => this.updateColor('regexp', color)),
							new Textbox('Selector Attributes', 'Changes the color of CSS selector attributes', this.hljs.selector_attr, (color) => this.updateColor('selector_attr', color)),
							new Textbox('Selector Classes', 'Changes the color of CSS selector classes', this.hljs.selector_class, (color) => this.updateColor('selector_class', color)),
							new Textbox('Selector IDs', 'Changes the color of CSS selector IDs', this.hljs.selector_id, (color) => this.updateColor('selector_id', color)),
							new Textbox('Selector Pseudos', 'Changes the color of CSS selector pseudos', this.hljs.selector_pseudo, (color) => this.updateColor('selector_pseudo', color)),
							new Textbox('Selector Tags', 'Changes the color of CSS selector tags', this.hljs.selector_tag, (color) => this.updateColor('selector_tag', color)),
							new Textbox('Strings', 'Changes the color of strings', this.hljs.string, (color) => this.updateColor('string', color)),
							new Textbox('Template Literals', 'Changes the color of template literals', this.hljs.template_variable, (color) => this.updateColor('template_variable', color)),
							new Textbox('Types', 'Changes the color of types', this.hljs.type, (color) => this.updateColor('type', color)),
							new Textbox('Variables', 'Changes the color of variables', this.hljs.variable, (color) => this.updateColor('variable', color)),
						)
					)
				}

				updateColor(property, color) {
					let reset = false

					if (!/#?\w{6}/.test(color) || color === '') {
						color = this.defaults[property]
						reset = true
					}

					if (!color.startsWith('#')) {
						color = `#${color}`
					}

					this.hljs[property] = color

					if (reset) PluginUtilities.saveSettings('BetterCodeblocks', this.hljs)

					PluginUtilities.removeStyle('BetterCodeblocks')
					PluginUtilities.addStyle('BetterCodeblocks', this.css)
				}

				inject(args, res) {
					const { render } = res.props;

					res.props.render = (props) => {
						const codeblock = render(props);
						const codeElement = codeblock.props.children;

						const classes = codeElement.props.className.split(' ');

						const lang = args ? args[0].lang : classes[classes.indexOf('hljs') + 1];
						const lines = codeElement.props.dangerouslySetInnerHTML
							? codeElement.props.dangerouslySetInnerHTML.__html
								.replace(
									/<span class="(hljs-[a-z]+)">([^<]*)<\/span>/g,
									(_, className, code) => code.split('\n').map(l => `<span class="${className}">${l}</span>`).join('\n')
								)
								.split('\n')
							: codeElement.props.children.split('\n');

						delete codeElement.props.dangerouslySetInnerHTML;

						codeElement.props.children = this.render(lang, lines);

						return codeblock;
					};
				}

				render(lang, lines) {
					const { Messages } = WebpackModules.getByProps('Messages')

					if (hljs && typeof hljs.getLanguage === 'function') {
						lang = hljs.getLanguage(lang);
					}

					return React.createElement(React.Fragment, null,
						lang && React.createElement('div', { className: 'bd-codeblock-lang' }, lang.name),

						React.createElement('table', { className: 'bd-codeblock-table' },
							...lines.map((line, i) => React.createElement('tr', null,
								React.createElement('td', null, i + 1),
								React.createElement('td',
									lang ? {
										dangerouslySetInnerHTML: {
											__html: line
										}
									} : {
											children: line
										}
								)
							))
						),

						React.createElement('button', {
							className: 'bd-codeblock-copy-btn',
							onClick: this.clickHandler
						}, Messages.COPY)
					);
				}

				clickHandler({ target }) {
					const { Messages } = WebpackModules.getByProps('Messages')
					const { clipboard } = require('electron')

					if (target.classList.contains('copied')) return;

					target.innerText = Messages.ACCOUNT_USERNAME_COPY_SUCCESS_1;
					target.classList.add('copied');

					setTimeout(() => {
						target.innerText = Messages.COPY;
						target.classList.remove('copied');
					}, 1e3);

					const code = [...target.parentElement.querySelectorAll('td:last-child')].map(t => t.textContent).join('\n');
					clipboard.writeText(code);
				}

				get css() {
					return `
				.hljs {
					background-color: ${this.hljs.background} !important;
					color: ${this.hljs.text};
					position: relative;
				}
				
				.hljs:not([class$='hljs']) {
					padding-top: 2px;
				}
				
				.bd-codeblock-lang {
					color: var(--text-normal);
					border-bottom: 1px solid var(--background-modifier-accent);
					padding: 0 5px;
					margin-bottom: 6px;
					font-size: .8em;
					font-family: 'Raleway', sans-serif;
					font-weight: bold;
				}
				
				.bd-codeblock-table {
					border-collapse: collapse;
				}
				
				.bd-codeblock-table tr {
					height: 19px;
					width: 100%;
				}
				
				.bd-codeblock-table td:first-child {
					border-right: 1px solid var(--background-modifier-accent);
					padding-left: 5px;
					padding-right: 8px;
					user-select: none;
				}
				
				.bd-codeblock-table td:last-child {
					padding-left: 8px;
					word-break: break-all;
				}
				
				.bd-codeblock-copy-btn {
					color: #fff;
					border-radius: 4px;
				
					line-height: 20px;
					padding: 0 10px;
					font-family: 'Raleway', sans-serif;
					font-size: .8em;
					text-transform: uppercase;
					font-weight: bold;
				
					margin: 3px;
					background: var(--background-floating);
					position: absolute;
					right: 0 !important;
					bottom: 0 !important;
					opacity: 0;
					transition: .3s;
				}
				
				.bd-codeblock-copy-btn.copied {
					background-color: #43b581;
					opacity: 1;
				}
				
				.hljs:hover .bd-codeblock-copy-btn {
					opacity: 1;
				}

				// HLJS Styling

				.hljs > .bd-codeblock-table > tr > td > span > .hljs-tag {
					color: ${this.hljs.tag};
				}

				.hljs > .bd-codeblock-table > tr > td > span > .hljs-tag > .hljs-name {
					color: ${this.hljs.name};
				}

				.hljs > .bd-codeblock-table > tr > td > span > .hljs-tag > .hljs-attr {
					color: ${this.hljs.attr_2};
				}

				.hljs > .bd-codeblock-table > tr > td > .bash > .hljs-built_in {
					color: ${this.hljs.built_in};
				}

				.hljs > .bd-codeblock-table > tr > td > .bash > .hljs-variable {
					color: ${this.hljs.variable};
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-tag {
					color: ${this.hljs.tag} !important;
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-tag > .hljs-name {
					color: ${this.hljs.tag};
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-tag > .hljs-attr {
					color: ${this.hljs.tag};
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-function > .hljs-params {
					color: ${this.hljs.params};
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-function > .hljs-params > .hljs-type {
					color: ${this.hljs.type};
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-params {
					color: ${this.hljs.params};
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-params > .hljs-built_in {
					color: ${this.hljs.built_in};
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-selector-attr {
					color: ${this.hljs.selector_attr};
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-type {
					color: ${this.hljs.type};
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-selector-id {
					color: ${this.hljs.selector_id};
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-selector-pseudo {
					color: ${this.hljs.selector_pseudo};
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-bullet {
					color: ${this.hljs.bullet};
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-addition {
					color: ${this.hljs.addition};
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-deletion {
					color: ${this.hljs.deletion};
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-regexp {
					color: ${this.hljs.regexp};
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-doctag {
					color: ${this.hljs.doctag};
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-built_in {
					color: ${this.hljs.built_in};
				}

				.hljs > .bd-codeblock-table > tr > td > .hljs-attr {
					color: ${this.hljs.attr_1};
				}

				.hljs > .bd-codeblock-table > tr > td .hljs-nomarkup > span {
					color: ${this.hljs.nomarkup};
				}

				.hljs > .bd-codeblock-table > tr > td .hljs-section {
					color: ${this.hljs.section};
				}

				.hljs > .bd-codeblock-table > tr > td .hljs-meta {
					color: ${this.hljs.meta};
				}
				
				.hljs > .bd-codeblock-table > tr > td .hljs-literal {
					color: ${this.hljs.literal};
				}

				.hljs > .bd-codeblock-table > tr > td .hljs-title {
					color: ${this.hljs.title};
				}

				.hljs > .bd-codeblock-table > tr > td .hljs-keyword {
					color: ${this.hljs.keyword};
				}

				.hljs > .bd-codeblock-table > tr > td .hljs-selector-tag {
					color: ${this.hljs.selector_tag};
				}
				
				.hljs > .bd-codeblock-table > tr > td .hljs-selector-class {
					color: ${this.hljs.selector_class};
				}

				.hljs > .bd-codeblock-table > tr > td .hljs-attribute {
					color: ${this.hljs.attribute};
				}

				.hljs > .bd-codeblock-table > tr > td .hljs-symbol {
					color: ${this.hljs.symbol};
				}

				.hljs > .bd-codeblock-table > tr > td .hljs-number {
					color: ${this.hljs.number};
				}

				.hljs > .bd-codeblock-table > tr > td .hljs-string {
					color: ${this.hljs.string};
				}

				.hljs > .bd-codeblock-table > tr > td .hljs-subst {
					color: ${this.hljs.subst};
				}

				.hljs > .bd-codeblock-table > tr > td .hljs-code {
					color: ${this.hljs.code};
				}

				.hljs > .bd-codeblock-table > tr > td .hljs-comment {
					color: ${this.hljs.comment};
				}
				
				.hljs > .bd-codeblock-table > tr > td .hljs-quote {
					color: ${this.hljs.quote};
				}

				.hljs > .bd-codeblock-table > tr > td .hljs-variable {
					color: ${this.hljs.variable};
				}

				.hljs > .bd-codeblock-table > tr > td .hljs-template-variable {
					color: ${this.hljs.template_variable};
				}
				
				.hljs > .bd-codeblock-table > tr > td .hljs-meta-string {
					color: ${this.hljs.meta_string};
				}

				// Chat CB
				.codeLine-14BKbG > span > span {
					color: ${this.hljs.text};
				}

				.codeLine-14BKbG > span > span > span > .hljs-tag {
					color: ${this.hljs.tag};
				}

				.codeLine-14BKbG > span > span > span > .hljs-tag > .hljs-name {
					color: ${this.hljs.name};
				}

				.codeLine-14BKbG > span > span > span > .hljs-tag > .hljs-attr {
					color: ${this.hljs.attr_2};
				}

				.codeLine-14BKbG > span > span > .bash > .hljs-built_in {
					color: ${this.hljs.built_in};
				}
				
				.codeLine-14BKbG > span > span > .bash > .hljs-variable {
					color: ${this.hljs.variable};
				}
				
				.codeLine-14BKbG > span > span > .hljs-tag {
					color: ${this.hljs.tag} !important;
				}
				
				.codeLine-14BKbG > span > span > .hljs-tag > .hljs-name {
					color: ${this.hljs.tag};
				}
				
				.codeLine-14BKbG > span > span > .hljs-tag > .hljs-attr {
					color: ${this.hljs.tag};
				}
				
				.codeLine-14BKbG > span > span > .hljs-function > .hljs-params {
					color: ${this.hljs.params};
				}
				
				.codeLine-14BKbG > span > span > .hljs-function > .hljs-params > .hljs-type {
					color: ${this.hljs.type};
				}
				
				.codeLine-14BKbG > span > span > .hljs-params {
					color: ${this.hljs.params};
				}
				
				.codeLine-14BKbG > span > span > .hljs-params > .hljs-built_in {
					color: ${this.hljs.built_in};
				}
				
				.codeLine-14BKbG > span > span > .hljs-selector-attr {
					color: ${this.hljs.selector_attr};
				}
				
				.codeLine-14BKbG > span > span > .hljs-type {
					color: ${this.hljs.type};
				}
				
				.codeLine-14BKbG > span > span > .hljs-selector-id {
					color: ${this.hljs.selector_id};
				}
				
				.codeLine-14BKbG > span > span > .hljs-selector-pseudo {
					color: ${this.hljs.selector_pseudo};
				}
				
				.codeLine-14BKbG > span > span > .hljs-bullet {
					color: ${this.hljs.bullet};
				}
				
				.codeLine-14BKbG > span > span > .hljs-addition {
					color: ${this.hljs.addition};
				}
				
				.codeLine-14BKbG > span > span > .hljs-deletion {
					color: ${this.hljs.deletion};
				}
				
				.codeLine-14BKbG > span > span > .hljs-regexp {
					color: ${this.hljs.regexp};
				}
				
				.codeLine-14BKbG > span > span > .hljs-doctag {
					color: ${this.hljs.doctag};
				}
				
				.codeLine-14BKbG > span > span > .hljs-built_in {
					color: ${this.hljs.built_in};
				}
				
				.codeLine-14BKbG > span > span > .hljs-attr {
					color: ${this.hljs.attr_1};
				}
				
				.codeLine-14BKbG > span > span .hljs-nomarkup > span {
					color: ${this.hljs.nomarkup};
				}
				
				.codeLine-14BKbG > span > span .hljs-section {
					color: ${this.hljs.section};
				}
				
				.codeLine-14BKbG > span > span .hljs-meta {
					color: ${this.hljs.meta};
				}
				
				.codeLine-14BKbG > span > span .hljs-literal {
					color: ${this.hljs.literal};
				}
				
				.codeLine-14BKbG > span > span .hljs-title {
					color: ${this.hljs.title};
				}
				
				.codeLine-14BKbG > span > span .hljs-keyword {
					color: ${this.hljs.keyword};
				}
				
				.codeLine-14BKbG > span > span .hljs-selector-tag {
					color: ${this.hljs.selector_tag};
				}
				
				.codeLine-14BKbG > span > span .hljs-selector-class {
					color: ${this.hljs.selector_class};
				}
				
				.codeLine-14BKbG > span > span .hljs-attribute {
					color: ${this.hljs.attribute};
				}
				
				.codeLine-14BKbG > span > span .hljs-symbol {
					color: ${this.hljs.symbol};
				}
				
				.codeLine-14BKbG > span > span .hljs-number {
					color: ${this.hljs.number};
				}
				
				.codeLine-14BKbG > span > span .hljs-string {
					color: ${this.hljs.string};
				}
				
				.codeLine-14BKbG > span > span .hljs-subst {
					color: ${this.hljs.subst};
				}
				
				.codeLine-14BKbG > span > span .hljs-code {
					color: ${this.hljs.code};
				}
				
				.codeLine-14BKbG > span > span .hljs-comment {
					color: ${this.hljs.comment};
				}
				
				.codeLine-14BKbG > span > span .hljs-quote {
					color: ${this.hljs.quote};
				}
				
				.codeLine-14BKbG > span > span .hljs-variable {
					color: ${this.hljs.variable};
				}
				
				.codeLine-14BKbG > span > span .hljs-template-variable {
					color: ${this.hljs.template_variable};
				}
				
				.codeLine-14BKbG > span > span .hljs-meta-string {
					color: ${this.hljs.meta_string};
				}
			`
				}
			};
		};
		return plugin(Plugin, Api);
	})(global.ZeresPluginLibrary.buildPlugin(config));
})();
/*@end@*/