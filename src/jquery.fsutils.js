(function($) {

	function showOverlay(targetElement, callback, params) {
		var flashWrapper = targetElement.fsutils.wrapper;
		var flashMovie = flashWrapper.data('movie');
		if (!flashMovie) {
			var args = Array.prototype.slice.call(arguments);
			return targetElement.fsutils.startupQueue.push(args);
		}
		flashMovie.setParams(params);
		flashWrapper.data('callback', callback);
		flashWrapper.data('target', targetElement);
		var position = targetElement.offset();
		flashWrapper.css({
			'left': position.left,
			'top': position.top,
			'width': targetElement.outerWidth(),
			'height': targetElement.outerHeight()
		});
	}

	/*
	 * FlashReplace is developed by Robert Nyman, http://www.robertnyman.com.
	 * License and downloads: http://code.google.com/p/flashreplace/
	*/

	var FlashReplace = {
		elmToReplace : null,
		flashIsInstalled : null,
		defaultFlashVersion : 7,
		replace : function (elmToReplace, src, id, width, height, version, params){
			if (typeof elmToReplace === 'string') {
				elmToReplace = document.getElementById(elmToReplace);
			}
			this.elmToReplace = elmToReplace;
			this.flashIsInstalled = this.checkForFlash(version || this.defaultFlashVersion);
			if(this.elmToReplace && this.flashIsInstalled){
				var obj = '<object' + ((window.ActiveXObject)? ' id="' + id + '" classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" data="' + src + '"' : '');
				obj += ' width="' + width + '"';
				obj += ' height="' + height + '"';
				obj += '>';
				var param = '<param';
				param += ' name="movie"';
				param += ' value="' + src + '"';
				param += '>';
				param += '';
				var extraParams = '';
				var extraAttributes = '';
				for(var i in params){
					extraParams += '<param name="' + i + '" value="' + params[i] + '">';
					extraAttributes += ' ' + i + '="' + params[i] + '"';
				}
				var embed = '<embed id="' + id + '" src="' + src + '" type="application/x-shockwave-flash" width="' + width + '" height="' + height + '"';
				var embedEnd = extraAttributes + '></embed>';
				var objEnd = '</object>';
				this.elmToReplace.innerHTML = obj + param + extraParams + embed + embedEnd + objEnd;
			}
			return this.elmToReplace;
		},

		checkForFlash : function (version){
			this.flashIsInstalled = false;
			var flash;
			if(window.ActiveXObject){
				try{
					flash = new ActiveXObject(("ShockwaveFlash.ShockwaveFlash." + version));
					this.flashIsInstalled = true;
				}
				catch(e){
					// Throws an error if the version isn't available
				}
			}
			else if(navigator.plugins && navigator.mimeTypes.length > 0){
				flash = navigator.plugins["Shockwave Flash"];
				if(flash){
					var flashVersion = navigator.plugins["Shockwave Flash"].description.replace(/.*\s(\d+\.\d+).*/, "$1");
					if(flashVersion >= version){
						this.flashIsInstalled = true;
					}
				}
			}
			return this.flashIsInstalled;
		}
	};

	$.fn.extend({
		'fsutils': {
			'startupQueue': [],
			'wrapper': null,
			'init': function() {
				var flashMovie = $('*[id]', this.wrapper)[0];
				this.wrapper.data('movie', flashMovie);

				flashMovie.addEventListener('onmouseevent', function(event) {
					var flashWrapper = jQuery().fsutils.wrapper;
					var flashWrapperPos = flashWrapper.position();
					if (event.type == 'mouseout') flashWrapper.css({
						'top': '-100000px',
						'left': '-100000px'
					});
					flashWrapper.data('target').trigger(jQuery.Event(event.type, {
						'pageX': (flashWrapperPos.left + event.stageX),
						'pageY': (flashWrapperPos.top + event.stageY)
					}));
				}.toString());

				flashMovie.addEventListener('onload', function() {
					var flashWrapper = jQuery().fsutils.wrapper;
					return flashWrapper.data('callback').apply(
						flashWrapper.data('target'), arguments
					);
				}.toString());

				flashMovie.addEventListener('onsave', function() {
					var flashWrapper = jQuery().fsutils.wrapper;
					return flashWrapper.data('callback').apply(
						flashWrapper.data('target'), arguments
					);
				}.toString());

				while (this.startupQueue.length) {
					showOverlay.apply(this, this.startupQueue.pop());
				}

			}
		},
		'openFileDialog': function(callback, filters) {
			this.mouseover(function() {
				var target = $(this);
				showOverlay(target, callback, {
					'dialogType': 'open',
					'cursor': target.css('cursor'),
					'fileFilter': filters.join(';')
				});
			});
			return $(this);
		},
		'saveFileDialog': function(callback) {
			this.mouseover(function() {
				var target = $(this);
				showOverlay(target, callback, {
					'dialogType': 'save',
					'cursor': target.css('cursor')
				});
			});
			return $(this);
		}
	});

	$(document).ready(function() {
		jQuery().fsutils.wrapper = $(FlashReplace.replace(document.createElement('div'), ([
			'script/fsutils.swf', Math.random()
		].join('?')), 'fsutils-flash', 900, 900, 9, {
			'FlashVars': 'onload=jQuery().fsutils.init',
				'wmode': 'transparent'
		})).css({
			'position': 'absolute',
			'z-index': '10000000',
			'top': '-100000px',
			'left': '-100000px',
			'overflow': 'hidden'
		}).appendTo(document.body);
	});

})(jQuery);