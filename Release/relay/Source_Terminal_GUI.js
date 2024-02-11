//This script is in the public domain.

var __source_terminal_gui_url = "Source_Terminal_GUI.ash";

var __selected_left_button = "educate";






//Min, max inclusive.
function randomi(min, max)
{
	return Math.floor(Math.random() * (max - min + 1)) + min;
}


function timeInMilliseconds()
{
    if (Date.now == undefined) //IE8 compatibility
        return Number(new Date);
    return Date.now();
}

//Matrix:
var __matrix_spinners = [];
var __matrix_spinner_counter = 0;
var __matrix_animation_interval = 16;
var __matrix_glyph_size = 8; //16;
var __matrix_idle_timer_interval = 10 * 1000;
var __matrix_activation_time = 60;
var __matrix_animating = false;
var __matrix_timer_id = 1;
var __matrix_last_event_time;

function matrixDrawGlyph(context, glyphs, glyph_index, x_index, y_index, alpha, colour)
{
	if (y_index < 0 || x_index < 0)
		return;
	var gx = glyph_index % 10;
	var gy = Math.floor(glyph_index / 10);
	
	context.globalCompositeOperation = "source-over";
	if (false)
	{
		context.globalAlpha = 1.0;
		context.fillStyle = "rgb(0,0,0)";
		context.fillRect(x_index * __matrix_glyph_size, y_index * __matrix_glyph_size, __matrix_glyph_size, __matrix_glyph_size);
	}
	//context.globalCompositeOperation = "lighter";
	context.globalAlpha = alpha;
	context.drawImage(glyphs, gx * __matrix_glyph_size, gy * __matrix_glyph_size, __matrix_glyph_size, __matrix_glyph_size, x_index * __matrix_glyph_size, y_index * __matrix_glyph_size, __matrix_glyph_size, __matrix_glyph_size);
	//context.globalCompositeOperation = "source-over";
	
	if (colour != "")
	{
		context.globalCompositeOperation = "multiply";
		context.fillStyle = colour; //"rgb(0,127,255)";
		context.fillRect(x_index * __matrix_glyph_size, y_index * __matrix_glyph_size, __matrix_glyph_size, __matrix_glyph_size);
		context.globalCompositeOperation = "source-over";
	}
}


function matrixTick(id)
{
    if (id < __matrix_timer_id) //out of line
        return;
        
        
	var context_width = 500; //window.innerWidth; //document.body.clientWidth;
	var context_height = 350; //window.innerHeight; //document.body.clientHeight;
	var canvas = document.getElementById("matrix_canvas");
    if (canvas == null)
        return;
	var canvas_holder = document.getElementById("matrix_canvas_holder");
    if (canvas_holder == null)
        return;
	var needs_resize = false;
	if (canvas.width != context_width)
		needs_resize = true;
	if (canvas.height != context_height)
		needs_resize = true;
	
	if (needs_resize)
	{
		var stored_data = undefined;
		try
		{
			//This is an invalid operation on file:// in chrome, so catch and fallback:
			stored_data = canvas.toDataURL();
			var previous_image = new Image;
			//Once the image has been parsed, resize and update:
			previous_image.onload = function()
			{
				canvas.width = context_width;
				canvas.height = context_height;
				canvas.getContext("2d").drawImage(previous_image, 0, 0);
				matrixTick(id);
			}
			previous_image.src = stored_data;
			return;
		}
		catch (exception)
		{
			canvas.width = context_width;
			canvas.height = context_height;
		}
	}
	
	var context = canvas.getContext("2d");
	
	var glyphs = document.getElementById("matrix_glyphs");
	if (glyphs == null)
        return;
	
	var maximum_glyphs_x = Math.ceil(context_width / __matrix_glyph_size);
	var maximum_glyphs_y = Math.ceil(context_height / __matrix_glyph_size);
	
	
	//Fade out:
	if (true)
	{
		//Subtraction method:
		context.globalCompositeOperation = "difference";
		context.fillStyle = "rgb(2, 2, 2)";
		context.globalAlpha = 1.0;
		context.fillRect(0, 0, context_width, context_height);
		context.globalCompositeOperation = "source-over";
	}
	else
	{
		//Alpha method:
		context.fillStyle = "rgb(0,0,0)";
		context.globalAlpha = 1.0 / __matrix_glyph_size; //1.0 / (60.0);
		context.fillRect(0, 0, context_width, context_height);
	}
	
	if (false)
	{
		//Fill the screen:
		for (var y = 0; y < maximum_glyphs_y; y++)
		{
			for (var x = 0; x < maximum_glyphs_x; x++)
			{
				var glyph_index = randomi(0, 102 - 1);
				var alpha = Math.random();
				matrixDrawGlyph(context, glyphs, glyph_index, x, y, alpha, "");
			}
		}
	}
	if (false)
	{
		//Random glyphs:
		for (var i = 0; i < 128; i++)
		{
			var x = randomi(0, maximum_glyphs_x);
			var y = randomi(0, maximum_glyphs_y);
			var glyph_index = randomi(0, 102 - 1);
			var alpha = Math.random();
			matrixDrawGlyph(context, glyphs, glyph_index, x, y, alpha, "");
		}
	}
	
	//Create spinners:
	var spinner_density = (context_width * context_height) / (__matrix_glyph_size * 256);
	while (__matrix_spinners.length < spinner_density)
	{
		var spinner = new Object();
		
		spinner.x_index = randomi(0, maximum_glyphs_x);
		spinner.y_index = randomi(-16, maximum_glyphs_y);
		spinner.alpha = Math.random(); //Math.random() * 0.25 + 0.75;
		spinner.counter = randomi(0, 11);
		spinner.glyph_index = randomi(0, 102 - 1);
		spinner.interval = randomi(1, 15);
		
		__matrix_spinners.push(spinner);
	}
	//Draw spinners:
	var spinners_next = [];
	for (var i = 0; i < __matrix_spinners.length; i++)
	{
		var spinner = __matrix_spinners[i];
		var should_delete = false;
		
		if (spinner.counter % spinner.interval == 0)
		{
			matrixDrawGlyph(context, glyphs, spinner.glyph_index, spinner.x_index, spinner.y_index, spinner.alpha, "");
			spinner.y_index++;
			spinner.glyph_index = randomi(0, 102 - 1);
			if (spinner.y_index > maximum_glyphs_y)
			{
				should_delete = true;
			}
		}
		if (Math.random() < 0.05 / 60.0)
			should_delete = true;
		if (spinner.interval > 1)
		{
			var percentage = ((spinner.counter % spinner.interval) + 1) / (spinner.interval);
			matrixDrawGlyph(context, glyphs, spinner.glyph_index, spinner.x_index, spinner.y_index, spinner.alpha * percentage, "");
		}
		if (!should_delete)
			spinners_next.push(spinner);
		
		spinner.counter++;
	}
	__matrix_spinners = spinners_next;
	__matrix_spinner_counter++;
	
	setTimeout(function() {matrixTick(id)}, __matrix_animation_interval);
}

function matrixStartAnimation()
{
    if (__matrix_animating)
        return;
    __matrix_last_event_time = timeInMilliseconds();
	var canvas_holder = document.getElementById("matrix_canvas_holder");
    
    if (canvas_holder === null)
        return;
    
    __matrix_timer_id++;
	setTimeout(function() {matrixTick(__matrix_timer_id)}, __matrix_animation_interval);
    __matrix_animating = true;
    
    canvas_holder.style.display = "inline";
    canvas_holder.style.visibility = "visible";
    canvas_holder.style.opacity = 0.0;
    canvas_holder.style.transition = "opacity 1.0s";
    canvas_holder.style.opacity = 1.0;
}

function matrixStopAnimation()
{
    if (!__matrix_animating)
        return;
    __matrix_last_event_time = timeInMilliseconds();
    __matrix_timer_id++; //will cancel any running timer
    __matrix_animating = false;
    
	var canvas_holder = document.getElementById("matrix_canvas_holder");
    if (canvas_holder == null)
        return;
    canvas_holder.style.visibility = "hidden";
    
    canvas_holder.style.opacity = 0.0;
}

function matrixCanvasStop()
{
    __matrix_last_event_time = timeInMilliseconds();
	matrixStopAnimation();
}

function matrixIdleTimer()
{
    if (__matrix_last_event_time == undefined)
    	__matrix_last_event_time = timeInMilliseconds();
    var seconds_since_last_matrix_event = (timeInMilliseconds() - __matrix_last_event_time) / 1000.0;
	//console.log("matrixIdleTimer(seconds_since_last_matrix_event = " + seconds_since_last_matrix_event + ")");
    if (seconds_since_last_matrix_event > __matrix_activation_time && !__matrix_animating)
        matrixStartAnimation();
    
	setTimeout(function() {matrixIdleTimer()}, __matrix_idle_timer_interval);
}









var __tested_pointer_events = false;
var __browser_probably_supports_pointer_events = false;
function browserProbablySupportsPointerEvents()
{
    if (!__tested_pointer_events)
    {
        var testing_element = document.createElement("pointerEventsTest");
        testing_element.style.cssText='pointer-events:auto';
        __browser_probably_supports_pointer_events = (testing_element.style.pointerEvents === 'auto');
        __tested_pointer_events = true;
    }
    return __browser_probably_supports_pointer_events;
}


function sourceTerminalGUIUpdateHTML()
{
	//Does the browser support mix-blend-mode? If not, disable the overlay, or they won't be able to see anything.
	//We don't use mix-blend-mode at the moment, so ignore:
	/*var mix_blend_mode_supported = false;
	try
	{
		mix_blend_mode_supported = CSS.supports("mix-blend-mode", "multiply");
		if (mix_blend_mode_supported == undefined)
			mix_blend_mode_supported = false;
	}
	catch (exception)
	{
	}
	if (!mix_blend_mode_supported)
	{
		document.getElementById("source_terminal_gui_overlay").style.visibility = "hidden";
		document.getElementById("source_terminal_gui_overlay_alternate").style.visibility = "visible";
	}*/
	//Does the browser support pointer events?
	if (!browserProbablySupportsPointerEvents())
	{
		//No, it doesn't, disable the overlay:
		document.getElementById("source_terminal_gui_overlay_alternate").style.visibility = "hidden";
	}
}


function sourceTerminalGUILoad()
{
	sourceTerminalGUIUpdateHTML();
	setTimeout(function() {matrixIdleTimer()}, __matrix_idle_timer_interval);
}

function recalculateLeftNavigationHighlighting(name_selected)
{
	__selected_left_button = name_selected;
	//Set style of left button:
	//Set style of right area:
	var names = ["educate", "enhance", "extrude", "enquiry", "terminal"];
	for (key in names)
	{
		var name = names[key];
		
		var enabled = name == name_selected;
		
		var right_div = document.getElementById("right_" + name);
		var left_button = document.getElementById("left_" + name);
		
		if (enabled)
		{
			right_div.style.display = "block";
			left_button.className = "left_button left_button_highlighted";
		}
		else
		{
			right_div.style.display = "none";
			left_button.className = "left_button left_button_unhighlighted";
		}
		
		//console.log(name);
	}
}


function parseHTMLUpdate(response_string)
{
	var response;
	try
	{
		response = JSON.parse(response_string);
	}
	catch (exception)
	{
		return;
	}
	var core_html = response["core html"];
	
	var main_container = document.getElementById("source_terminal_gui_main_container");
	main_container.innerHTML = core_html;
	sourceTerminalGUIUpdateHTML();
	recalculateLeftNavigationHighlighting(__selected_left_button);
}

function requestRefresh()
{
	var form_data = "type=refresh";
	var request = new XMLHttpRequest();
	request.onreadystatechange = function() { if (request.readyState == 4) { if (request.status == 200) { parseHTMLUpdate(request.responseText); } } }
	request.open("POST", __source_terminal_gui_url);
	request.send(form_data);
}

function activateTerminal()
{
	document.getElementById("source_terminal_gui_main_container").style.visibility = "hidden";
	document.getElementById("source_terminal_gui_popup_container").style.visibility = "hidden";
	document.getElementById("term").style.visibility = "visible";
	document.getElementById("source_terminal_gui_terminal_return").style.visibility = "visible";
}

function deactivateTerminal()
{
	document.getElementById("source_terminal_gui_main_container").style.visibility = "visible";
	document.getElementById("source_terminal_gui_popup_container").style.visibility = "visible";
	document.getElementById("term").style.visibility = "hidden";
	document.getElementById("source_terminal_gui_terminal_return").style.visibility = "hidden";
	
	//Request update, in case they changed something:
	requestRefresh();
}

function leftNavigationClick(event, name_clicked)
{
	if (name_clicked == "terminal")
	{
		activateTerminal();
		
		return;
	}
	recalculateLeftNavigationHighlighting(name_clicked);
}

function deleteElement(parent_element, element)
{
	try
	{
		parent_element.removeChild(element);
	}
	catch (exception)
	{
		return;
	}
	
}

function fadeOutPopup(parent_element, popup_element)
{
	popup_element.style.opacity = 0.0;
	setTimeout(function() {deleteElement(parent_element, popup_element)}, 1000);
	
}

function parseButtonClickResponse(response_string)
{
	//console.log("parseButtonClickResponse()");
	parseHTMLUpdate(response_string);
	var response;
	try
	{
		response = JSON.parse(response_string);
	}
	catch (exception)
	{
		return;
	}
	
	var popup_result = response["popup result"];
	if (popup_result != undefined)
	{
		var popup_container = document.getElementById("source_terminal_gui_popup_container");
		
		//Move the rest of them up:
		var other_elements = popup_container.getElementsByClassName("source_terminal_gui_popup");
		
		if (other_elements != undefined)
		{
			for (var i = 0; i < other_elements.length; i++)
			{
				var element = other_elements[i];
				var current_value = 0;
				if (element.style.marginTop != "")
					current_value = element.style.marginTop.replace("px", "");
				var new_value = current_value - 30;
				element.style.marginTop = new_value + "px";
			}
		}
		
		//Add one:
		
		var new_popup = document.createElement("div");
		new_popup.innerHTML = popup_result;
		//new_popup.style = "";
		new_popup.setAttribute("class", "source_terminal_gui_popup");
		popup_container.appendChild(new_popup);
		setTimeout(function() {fadeOutPopup(popup_container, new_popup)}, 7000);
	}
	
}

function actionButtonClicked(event, page_name, button_title)
{
	//console.log("actionButtonClicked(page_name = " + page_name + " button_title = " + button_title + ")");
	
	//Submit to script:
	
	var form_data = "type=button_clicked&page_name=" + page_name + "&button_title=" + button_title;
	var request = new XMLHttpRequest();
	request.onreadystatechange = function() { if (request.readyState == 4) { if (request.status == 200) { parseButtonClickResponse(request.responseText); } } }
	request.open("POST", __source_terminal_gui_url);
	request.send(form_data);
}
