<!DOCTYPE html>
<html lang="en">
	<head>
		<meta http-equiv="X-UA-Compatible" content="IE=edge" />
		<meta charset="UTF-8" />
		<title></title>
		  <link rel="stylesheet" href="jquery-ui.css">

		<script type="text/javascript" src="jquery.min.js"></script>
		<script type="text/javascript" src="jquery-ui.js"></script>
		<script type="text/javascript" src="dmtemplate-ui.js"></script>
		<script type="text/javascript">
			
			

			var tplsendjob;
			var jsonsendjob;
			$(document).ready(function() {
				$("#tpltext").keyup(function(event) {
					clearTimeout(tplsendjob);
					tplsendjob = setTimeout(function () {runByond({"action":"tplupdate", "text":$(event.target).val()});}, 250);
				});

				$("#jsontext").keyup(function(event) {
					clearTimeout(jsonsendjob);
					jsonsendjob = setTimeout(function () {runByond({"action":"jsonupdate", "text":$(event.target).val()});}, 250);
				});
				$("textarea").resizable();
				runByond({"action":"tplupdate", "text":$("#tpltext").val()});
				runByond({"action":"jsonupdate", "text":$("#jsontext").val()});
			});
		</script>
		<style>
			
			.ui-resizable-handle {
				transform: translate(-75%, -75%);
				
			}

			.column {
				float: left;
				width: 33.33%;
				height:100%;
				overflow: auto;
			}
			.row {
				flex: 1 1 auto;
				width:100%;
				height:100%; 
			}
			/* Clear floats after the columns */
			.row:after {
				content: "";
				display: table;
				clear: both;
			}
			p.error {
				color: red;
			}
		</style>
	</head>
	<body>
	<div class="row">
		<div class="column">
			<h3>Template</h3>
			<textarea rows="32" cols="40" id="tpltext">
<h2>Hello {{!#if name}}{{!name}}{{!/if1}}{{!#if! name}}Person{{!/if2}}</h2>

{{!#ifempty! messages}}
<P>You have new messages</P>
{{!#foreach messages message_number message_key message_value}}
<P><b>Message</b> #{{!message_number}}</P>
<P><b>From:</b> {{!message_key["author"]}}</P>
<P><b>Contents:</b> {{!message_key["message"]}}</P>
<br>
{{!/foreach}}
{{!/if}}
{{!#ifempty messages}}
You have no new messages
{{!/if}}
{{!!End}}
{{!#if}}
You can do an if with no expression for template comments.

You can escape brackets with a ! in the first character.

{{!/if4}}
</textarea>
			{{#if %tplerror}}
				<p class="error">{{%tplerror}}</p>
			{{/if5}}
		</div>
		<div class="column">
			<h3>Rendered</h3>
			{{%*rendered}}
		</div>
		<div class="column">
			<h3>Data</h3>
			<textarea rows="30" cols="40" id="jsontext">{
  "name": "MrStonedOne",
  "messages": [
    {
      "author": "Iamgoofball",
      "message": "Rig the election for me please!"
    },
    {
      "author": "The Frog",
      "message": "Don't let me win, give mikey all my votes"
    }
]
}</textarea>
			{{#if %jsonerror}}
				<p class="error">{{%jsonerror}}</p>
			{{/if6}}
		</div>
	</div>
	<div id="log"></div>
	</body>
</html>