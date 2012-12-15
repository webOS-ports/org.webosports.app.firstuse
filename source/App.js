enyo.kind({
	name: "App",
	classes: "enyo-fit",
	layoutKind: "FittableRowsLayout",style: "padding: 8px",
	licenseAccepted: false,
	components:[
		{name: "OpacityAnimator", kind: "Animator", startValue: 1, endValue: 0, duration: 1000, onStep: "animatorStep", onEnd: "animatorEnd"},
		{kind: "Scroller", fit: true, touch: true, horizontal: "hidden", components:[
			{kind: "PortsHeader",
			title: "License",
			style: "height: 42px;",
			taglines: [
				"You're definitely going to read this, right?",
				"Lots of text!",
				"FOSS!",
				"Scroll scroll scroll scroll tap.",
				"Will you take the red pill, or the green pill?"
			]},
			{content: "LICENSE PLACEHOLDER<br>You (the user) hereby agree to be generally apathetic about this piece of text (the piece of text).", allowHtml: true, style: "padding: 10px; color: white;"}
		]},
		{tag: "div", style: "margin: 8px 8% 0 8%; padding: 0; line-height: 42px;", layoutKind: "FittableColumnsLayout", components:[
			{kind: "onyx.Button", style: "width: 45%; color: white; background-color: darkred;", content: "Decline", ontap: "declineLicense"},
			{fit: true},
			{kind: "onyx.Button", style: "width: 45%; color: white; background-color: green;", content: "Accept", ontap: "acceptLicense"}
		]}
	],
	rendered: function(inSender, inEvent) {
		this.inherited(arguments);
		this.$.OpacityAnimator.setStartValue(0);
		this.$.OpacityAnimator.setEndValue(1);
		this.$.OpacityAnimator.play();
	},
	acceptLicense: function(inSender, inEvent) {
		this.licenseAccepted = true;
		this.$.OpacityAnimator.setStartValue(1);
		this.$.OpacityAnimator.setEndValue(0);
		this.$.OpacityAnimator.play();
	},
	declineLicense: function(inSender, inEvent) {
		this.$.OpacityAnimator.setStartValue(1);
		this.$.OpacityAnimator.setEndValue(0);
		this.$.OpacityAnimator.play();
	},
	animatorStep: function(inSender, inEvent) {
		enyo.Arranger.opacifyControl(this, inSender.value);
	},
	animatorEnd: function(inSender, inEvent) {
		if(this.licenseAccepted == true) {
			/* this will create the needed /var/luna/preferences/ran-first-use file to start
			 * LunaSysMgr in lunaui mode */
			PalmSystem.markFirstUseDone();
		}
		
		if(this.$.OpacityAnimator.endValue == 0) {
			//This should shutdown the device, but for now just restarts firstuse luna again
			PalmSystem.shutdown();
		}
	}
});
