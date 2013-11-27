var domain = "api.weipan.cn";
var scheme = "native";
var callback_id = 0;	
	
function run_command(path, parms) {
            
	if (!this.nativeBridge) {
        		
        		this.nativeBridge = document.createElement("iframe");
				this.nativeBridge.setAttribute("style", "display:none;");
				this.nativeBridge.setAttribute("height", "0px");
				this.nativeBridge.setAttribute("width", "0px");
				this.nativeBridge.setAttribute("frameborder", "0");
				document.documentElement.appendChild(this.nativeBridge);
    }
    		
    callback_id ++;
            
   	var url = scheme + "://" + domain + "/" + path + "?callback_id=" + callback_id + "&" + parms;
    		
    this.nativeBridge.src = url;
}

function JSLog(msg) {
    
    run_command('JSLog', 'msg=' + encodeURIComponent(msg));
}


/**
 * 回到页面顶部
 * @param acceleration 加速度
 * @param time 时间间隔 (毫秒)
 **/
 
function goTop(acceleration, time) {

	acceleration = acceleration || 0.1;
	time = time || 16;
 
	var x1 = 0;
	var y1 = 0;
	var x2 = 0;
	var y2 = 0;
	var x3 = 0;
	var y3 = 0;
 
	if (document.documentElement) {
		x1 = document.documentElement.scrollLeft || 0;
		y1 = document.documentElement.scrollTop || 0;
	}
	if (document.body) {
		x2 = document.body.scrollLeft || 0;
		y2 = document.body.scrollTop || 0;
	}
	var x3 = window.scrollX || 0;
	var y3 = window.scrollY || 0;
 
	// 滚动条到页面顶部的水平距离
	var x = Math.max(x1, Math.max(x2, x3));
	// 滚动条到页面顶部的垂直距离
	var y = Math.max(y1, Math.max(y2, y3));
 
	// 滚动距离 = 目前距离 / 速度, 因为距离原来越小, 速度是大于 1 的数, 所以滚动距离会越来越小
	var speed = 1 + acceleration;
	window.scrollTo(Math.floor(x / speed), Math.floor(y / speed));
 
	// 如果距离不为零, 继续调用迭代本函数
	if(x > 0 || y > 0) {
		var invokeFunction = "goTop(" + acceleration + ", " + time + ")";
		window.setTimeout(invokeFunction, time);
	}
}