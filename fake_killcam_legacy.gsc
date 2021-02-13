#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_hud_message;
#include maps\mp\gametypes\_rank;

init(){
	level.clientid = 0;
	level thread onplayerconnect();
	precacheshader("emblem_bg_default");
	precacheshader("rank_com_128");
}

onplayerconnect(){
	for (;;){
		level waittill("connecting", player);
		player.clientid = level.clientid;
		level.clientid++;
		player thread hud();
	}
}

overlay(on, attacker, final){
	if(on){
		name = attacker.name;
		tag = "";
		prefix = -1;
		postfix = -1;
		color = (1,0,0);
		toptext = "KILLCAM";
		for(i = 0; i < attacker.name.size; i++){
			if(attacker.name[i] == "[" && prefix == -1){
				prefix = i;
			}else if(attacker.name[i] == "]" && postfix == -1){
				postfix = i;
			}
		}
		if(prefix != -1 && postfix != -1){
			tag = getsubstr(attacker.name, prefix, postfix + 1);
			name = getsubstr(attacker.name, postfix + 1);
		}
		if(final){
			color = (0,0,0);
			toptext = "ROUND ENDING KILLCAM";
		}
		self.hud = [];
		self.hud[0] = self shader("CENTER", "CENTER", 0, -200, "white", 854, 80, color, 0.2, 1); //top bar
		self.hud[1] = self shader("CENTER", "CENTER", 0, 200, "white", 854, 80, color, 0.2, 1); //bot bar
		self.hud[2] = self shader("CENTER", "CENTER", 0, 180, "emblem_bg_default", 160, 40, (1, 1, 1), 0.9, 2); //calling card
		self.hud[3] = self shader("CENTER", "CENTER", 5, 188, "rank_com_128", 16, 16, (1, 1, 1), 1, 3); //player rank
		self.hud[4] = self drawtext(name, "LEFT", "CENTER", -44, 171, 1.25, "default", (1,1,1), 1, 3); //player name
		self.hud[5] = self drawtext(tag, "LEFT", "CENTER", -44, 188, 1.25, "default", (1,1,1), 1, 3); //player tag
		self.hud[6] = self drawtext(toptext, "CENTER", "CENTER", 0, -180, 3.25, "default", (1,1,1), 1, 3); //top text
	}else{
		self.hud[0] destroy();
		self.hud[1] destroy();
		self.hud[2] destroy();
		self.hud[3] destroy();
		self.hud[4] destroy();
		self.hud[5] destroy();
		self.hud[6] destroy();
	}
}

hud(){
	self waittill("spawned_player");
    self setclientuivisibilityflag("hud_visible", 0);
	self overlay(true, self);
	wait 15;
	self overlay(false);
	// self.hud = [];
	// self.hud[0] = self shader("CENTER", "CENTER", 0, -200, "white", 854, 80, (0, 0, 0), 0.2, 1); //top bar
	// self.hud[1] = self shader("CENTER", "CENTER", 0, 200, "white", 854, 80, (0, 0, 0), 0.2, 1); //bot bar
	// self.hud[2] = self shader("CENTER", "CENTER", 0, 180, "emblem_bg_default", 160, 40, (1, 1, 1), 0.9, 2); //calling card
	// self.hud[3] = self shader("CENTER", "CENTER", 5, 188, "rank_com_128", 16, 16, (1, 1, 1), 1, 3); //player rank
	// self.hud[4] = self drawtext("birchy", "LEFT", "CENTER", -44, 171, 1.25, "default", (1,1,1), 1, 3);
	// self.hud[5] = self drawtext("[3arc]", "LEFT", "CENTER", -44, 188, 1.25, "default", (1,1,1), 1, 3);
	// self.hud[6] = self drawtext("FINAL KILLCAM", "CENTER", "CENTER", 0, -180, 3.25, "default", (1,1,1), 1, 3);

// 	index = 4;
// 	counter = 0;
// 	fs = 1.25;
// 	visible = 1;

// 	for(;;){
// 		counter++;
// 		if(counter > 10){
// 			counter = 0;
// 		}
// 		wait 0.05;
// 		if(self jumpbuttonpressed()){
// 			index++;
// 			if(index > 5){
// 				index = 4;
// 			}
// 		}else if(self adsbuttonpressed()){
// 			self.hud[index].posx = self.hud[index].posx + 1;
// 		}else if(self attackbuttonpressed()){
// 			self.hud[index].posx = self.hud[index].posx - 1;
// 		}else if(self secondaryoffhandbuttonpressed()){
// 			self.hud[index].posy = self.hud[index].posy + 1;
// 		}else if(self fragbuttonpressed()){
// 			self.hud[index].posy = self.hud[index].posy - 1;
// 		}else if(self actionslotonebuttonpressed()){
// 			fs = fs + 0.05;
// 		}else if(self actionslottwobuttonpressed()){
// 			fs = fs - 0.05;
// 		}else if(self actionslotthreebuttonpressed()){
// 			if(visible == 1){
// 				visible = 0;
// 				self setclientuivisibilityflag("hud_visible", 0);
// 			}else{
// 				visible = 1;
// 				self setclientuivisibilityflag("hud_visible", 1);
// 			}
// 		}
// 		x = self.hud[index].posx;
// 		y = self.hud[index].posy;
// 		self.hud[index] destroy();
// 		if(index == 4){
// 			self.hud[index] = self drawtext("birchy", "LEFT", "CENTER", x, y, fs, "default", (1,1,1), 1, 3);
// 		}else{
// 			self.hud[index] = self drawtext("[3arc]", "LEFT", "CENTER", x, y, fs, "default", (1,1,1), 1, 3);
// 		}
			
// 		if(counter == 0){
// 			self iprintlnbold(index + " - " + fs + ": " + self.hud[index].posx + " - " + self.hud[index].posy);
// 		}
//    }
}

drawtext(text, align, relative, x, y, fontscale, font, color, alpha, sort){
    element = self createfontstring(font, fontscale);
    element setpoint(align, relative, x, y);
    element settext(text);
    element.hidewheninmenu = true;
    element.color = color;
    element.alpha = alpha;
    element.sort = sort;
    return element;
} 

shader(align, relative, x, y, shader, width, height, color, alpha, sort){
    element = newclienthudelem(self);
    element.elemtype = "bar";
    element.hidewheninmenu = true;
    element.shader = shader;
    element.width = width;
    element.height = height;
    element.align = align;
    element.relative = relative;
    element.xoffset = 0;
    element.yoffset = 0;
    element.children = [];
    element.sort = sort;
    element.color = color;
    element.alpha = alpha;
    element setparent(level.uiparent);
    element setshader(shader, width, height);
    element setpoint(align, relative, x, y);
    return element;
}
