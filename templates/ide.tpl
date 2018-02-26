<!DOCTYPE html>
<html lang="en">
	<head>
		<meta http-equiv="X-UA-Compatible" content="IE=edge" />
		<meta charset="UTF-8" />
		<title></title>
		  <link rel="stylesheet" href="jquery-ui.css">

		<script type="text/javascript" src="jquery.min.js"></script>
		<script type="text/javascript" src="jquery-ui.js"></script>
		<script type="text/javascript" src="html_interface.js"></script>
		<script type="text/javascript">
			function runByond(uri) {
				window.location = uri;
			}
			var tplsendjob;
			var jsonsendjob;
			$(document).ready(function() {
				$("#tpltext").keyup(function(event) {
					clearTimeout(tplsendjob);
					tplsendjob = setTimeout(function () {runByond("?action=tplupdate&text="+encodeURIComponent($(event.target).val()))}, 200);
				});

				$("#jsontext").keyup(function(event) {
					clearTimeout(jsonsendjob);
					jsonsendjob = setTimeout(function () {runByond("?action=jsonupdate&text="+encodeURIComponent($(event.target).val()))}, 200);
				});
				$("textarea").resizable();
				runByond("?action=tplupdate&text="+encodeURIComponent($("#tpltext").val()));
				runByond("?action=jsonupdate&text="+encodeURIComponent($("#jsontext").val()));
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
<h2>Hello {!#IFDEF:NAME}{!NAME}{!#ENDIF}{!#IFNDEF:NAME}Person{!#ENDIF}</h2>

{!#IFNEMPTY:MESSAGES}
<P>You have new messages</P>
{!#ARRAY:MESSAGES}
<P><b>Message</b> #{!MESSAGES-INDEX}</P>
<P><b>From:</b> {!AUTHOR}</P>
<P><b>Contents:</b> {!MESSAGE}</P>
<br>
{!/ARRAY}
{!#ENDIF}
{!#IFEMPTY:MESSAGES}
You have no new messages
{!#ENDIF}
{!!END}
{!#IFDEF}
You can do an ifdef with no variable for template comments.

Brackets are not parsed if there is any spaces within them.

You can escape brackets with a ! in the first character.

Within arrays if the list value isn't itself a list, you can use VARNAME-KEY and VARNAME-VALUE to access the actual values.

Most of this syntax is subject to change as i'll be rewriting the compiler to be faster and in the mist of that making it more compatible with existing tgui templates.
{!#ENDIF}
</textarea>
			{#IFDEF:%TPLERROR}
				<p class="error">{%TPLERROR}</p>
			{#ENDIF}
		</div>
		<div class="column">
			<h3>Rendered</h3>
			{%RENDERED}
		</div>
		<div class="column">
			<h3>Data</h3>
			<textarea rows="30" cols="40" id="jsontext">{
  "NAME": "MrStonedOne",
  "MESSAGES": [
    {
      "AUTHOR": "Iamgoofball",
      "MESSAGE": "Rig the election for me please!"
    },
    {
      "AUTHOR": "The Frog",
      "MESSAGE": "Don't let me win, give mikey all my votes"
    }
]
}</textarea>
			{#IFDEF:%JSONERROR}
				<p class="error">{%JSONERROR}</p>
			{#ENDIF}
		</div>
	</div>
	<div id="log"></div>
	</body>
</html>