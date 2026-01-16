<script>

//////////////////////////////////////////////////////////////////////////
//	Print an error message and die with a stack trace.		//
//////////////////////////////////////////////////////////////////////////
function fatal( msg )
    {
    alert(msg);
    return 1;
    try		{ throw new Error(); }
    catch(e)	{ alert( msg + "\n" + e.stack ); }
    return undefined;
    }

//////////////////////////////////////////////////////////////////////////
//	Get pointer to an ID but give a reasonable message if it does	//
//	not exist.  "should never happen".  Uh huh.			//
//////////////////////////////////////////////////////////////////////////
function ebid( id )
    {
    var p = document.getElementById(id);
    // alert("ebid("+id+") yielded ["+(p||"UNDEF")+"]");
    if( ! p )
	{ fatal("Cannot find element for id ["+id+"]"); }
    return p;
    }

//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
function display_by_id( id, new_value )
    {
    (ebid(id)).style.display = new_value;
    }

//////////////////////////////////////////////////////////////////////////
//	User has hit a help button.					//
//////////////////////////////////////////////////////////////////////////
var help_window;
function show_help( help_page )
    {
    var url = "help/" + help_page;

    // Cannot use ebid() because not finding help_id is not fatal.
    var p = document.getElementById('help_id');
    if( p )
	{
	p.src = url;
	p.style.display = "";
	}
    else
        {
	help_window = window.open( url, '_help' );
	help_window.focus();
	}

    return false;
    }

//////////////////////////////////////////////////////////////////////////
//	One of the onXXXX happened.  Figure out which.			//
//////////////////////////////////////////////////////////////////////////
var touchstart_at;
function help_event( e, help_page )
    {
    if( e.type == "contextmenu" )
        {
	show_help( help_page );
	if( e.preventDefault ) { e.preventDefault(); }
	e.stopImmediatePropagation();
	}
    else if( e.type == "touchstart" )
        {
	touchstart_at = new Date().getTime();
	}
    else if( e.type == "touchend"
		&& ((new Date().getTime()) - touchstart_at) > 2000 )
        {
	show_help( help_page );
	if( e.preventDefault ) { e.preventDefault(); }
	e.stopImmediatePropagation();	// Not exactly redundant!
	}
    }

//////////////////////////////////////////////////////////////////////////
//	User is done with the help page (which was in an iframe).	//
//	Just make it invisible.						//
//////////////////////////////////////////////////////////////////////////
function done_help()
    {
    (ebid('help_id')).style.display = "none";
    }

//////////////////////////////////////////////////////////////////////////
//	Submit the current or named form.				//
//////////////////////////////////////////////////////////////////////////
function do_submit( ...args )
    {
    var current_form = "form";
    var argind=0;
    while( argind < args.length )
	{
	var varname = args[argind++];
	var varval = args[argind++]
	if( varname == "form" )
	    { current_form = varval; }
	else
	    { window.document[current_form][varname].value = varval; }
	}
    window.document[current_form].submit();
    }

</script>
