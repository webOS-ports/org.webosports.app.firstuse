enyo.kind({
	name: "App",
	classes: "enyo-fit",
	layoutKind: "FittableRowsLayout",
	components:[
		{kind: "PortsHeader",
		title: "License",
		taglines: [
			"You're definitely going to read this, right?",
			"Lots of text!",
			"FOSS!",
			"Scroll scroll scroll scroll tap.",
			"Will you take the red pill, or the green pill?"
		]},
		{kind: "Scroller", fit: true, touch: true, horizontal: "hidden", components:[
			{content: "LICENSE PLACEHOLDER<br>You (the user) hereby agree to be generally apathetic about this piece of text (the piece of text).", allowHtml: true, style: "padding: 10px; color: white;"}
		]},
		{kind: "onyx.Toolbar", style: "line-height: 42px;", layoutKind: "FittableColumnsLayout", components:[
			{kind: "onyx.Button", style: "width: 45%; background-color: darkred;", content: "Decline"},
			{fit: true},
			{kind: "onyx.Button", style: "width: 45%; background-color: green;", content: "Accept", ontap: "acceptLicense" }
		]}
	],
	acceptLicense: function(inSender, inEvent) {
		/* this will create the needed /var/luna/preferences/ran-first-use file to start
		 * LunaSysMgr in lunaui mode */
		PalmSystem.markFirstUseDone();
		/* NOTE: this will trigger a restart of the LunaSysMgr as it exits and upstart
		 * will restart it immediately */
		PalmSystem.shutdown();
	}
});
