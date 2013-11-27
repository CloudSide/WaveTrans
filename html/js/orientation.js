
var supportsOrientationChange = "onorientationchange" in window,
orientationEvent = supportsOrientationChange ? "orientationchange" : "resize";
     
function resizeViewport(scale) {
     
	var meta = document.getElementsByTagName('meta');
	
	for(var i=0; i<meta.length; i++) {
		
		if (meta[i].getAttribute('name') == 'viewport') {
			
			meta[i].setAttribute('content', 'width=device-width,initial-scale=' + scale + ',minimum-scale=' + scale + ',maximum-scale=1.0,user-scalable=yes');
			break;
		}
	}
}
     
// 监听事件
window.addEventListener(orientationEvent, function() {

	var ua = navigator.userAgent;
	var deviceType = "";

	//判断设备类型
	if (ua.indexOf("iPad") > 0 || ua.indexOf("iPhone") > 0 || ua.indexOf("iOS") > 0) {

		deviceType = "iOS";
	
	} else if (ua.indexOf("Android") > 0) {

		deviceType = "Android";

	} else {

		alert("既不是iOS，也不是安卓！");
		return;
	}


	// 判断横竖屏
	if ("iOS" == deviceType) {
	
		if (Math.abs(window.orientation) == 90) { //横屏
	
			//resizeViewport('0.48');
			
			
			var meta = document.getElementsByTagName('meta');
	
			for(var i=0; i<meta.length; i++) {
		
				if (meta[i].getAttribute('name') == 'viewport') {
			
					meta[i].setAttribute('content', 'width=device-height,initial-scale=0.48,minimum-scale=0.48,maximum-scale=1.0,user-scalable=yes');
					break;
				}
			}
	
		} else {
	
			//resizeViewport('0.32');
			//document.getElementById('reload_button').innerHTML("我是iOS的横屏");
			//alert("我是iOS的竖屏 ||");
			
			var meta = document.getElementsByTagName('meta');
	
			for(var i=0; i<meta.length; i++) {
		
				if (meta[i].getAttribute('name') == 'viewport') {
			
					meta[i].setAttribute('content', 'width=device-width,initial-scale=0.32,minimum-scale=0.32,maximum-scale=1.0,user-scalable=yes');
					break;
				}
			}
			
		}

	} else if ("Android" == deviceType ) {

		if (Math.abs(window.orientation) != 90) {

			alert("我是Android的横屏");

		} else {

			alert("我是Android的竖屏");
		}
	}
		
}, false);

// 判断横竖屏
if (Math.abs(window.orientation) == 90) { //横屏

	//resizeViewport('0.48');
	
	
	var meta = document.getElementsByTagName('meta');

	for(var i=0; i<meta.length; i++) {

		if (meta[i].getAttribute('name') == 'viewport') {
	
			meta[i].setAttribute('content', 'width=device-height,initial-scale=0.48,minimum-scale=0.48,maximum-scale=1.0,user-scalable=yes');
			break;
		}
	}

} else {

	//resizeViewport('0.32');
	//document.getElementById('reload_button').innerHTML("我是iOS的横屏");
	//alert("我是iOS的竖屏 ||");
	
	var meta = document.getElementsByTagName('meta');

	for(var i=0; i<meta.length; i++) {

		if (meta[i].getAttribute('name') == 'viewport') {
	
			meta[i].setAttribute('content', 'width=device-width,initial-scale=0.32,minimum-scale=0.32,maximum-scale=1.0,user-scalable=yes');
			break;
		}
	}
	
}

	

