package {

	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.system.*;
	import flash.external.ExternalInterface;
	import com.dynamicflash.util.Base64;

	public class fsutils extends Sprite {

		private var square: Sprite;
		private var settings: Object;
		private var fileRef: FileReference;
		private var eventListeners: Object = {};
		private var mouseEvents: Array = new Array(
			MouseEvent.MOUSE_OVER,
			MouseEvent.MOUSE_DOWN,
			MouseEvent.MOUSE_UP,
			MouseEvent.CLICK,
			MouseEvent.DOUBLE_CLICK,
			MouseEvent.MOUSE_MOVE,
			MouseEvent.MOUSE_OUT
		);

		private function onMouseEvent(event: MouseEvent): void {
			if (!this.eventListeners['onmouseevent']) return;
			ExternalInterface.call(this.eventListeners['onmouseevent'], {
				"type": event.type.toLowerCase(),
				"stageX": event.stageX,
				"stageY": event.stageY
			});
		}

		public function fsutils() {
			Security.allowDomain("*");
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			this.stage.align = StageAlign.TOP_LEFT;
			this.square = new Sprite();
			this.square.graphics.beginFill(0x000000, 0);
			this.square.graphics.drawRect(0, 0, 1000, 1000);
			this.square.graphics.endFill();
			this.square.buttonMode = true;
			this.square.mouseChildren = false;
			addChild(this.square);
			ExternalInterface.addCallback("setParams", this.setParams);
			ExternalInterface.addCallback("addEventListener", this.setEventListener);
			this.addEventListener(MouseEvent.CLICK, openDialog);
			for each (var mouseEvent:String in this.mouseEvents) {
				this.addEventListener(mouseEvent, onMouseEvent);
			}
			ExternalInterface.call(this.stage.loaderInfo.parameters["onload"]);
		}

		private function openDialog(event: MouseEvent): void {
			var dialogType: String = this.settings["dialogType"];
			var fileFilterValue: String = this.settings["fileFilter"];
			this.fileRef = new FileReference;
			if (dialogType == "open") {
				this.fileRef.addEventListener(Event.CANCEL, fileReference_cancel);
				this.fileRef.addEventListener(Event.SELECT, fileReference_select);
				var fileFilter:FileFilter = new FileFilter("Files: ("+fileFilterValue+")", fileFilterValue);
				this.fileRef.browse([fileFilter]);
			} else if (dialogType == "save") {
				var getData: Object = {};
				var dataForSave: String = "";
				var fileNameForSave: String = "";
				if (this.eventListeners['onsave']) {
					getData = ExternalInterface.call(this.eventListeners['onsave']);
					if (getData) {
						if (getData['data']) dataForSave = getData['data'];
						if (getData['filename']) fileNameForSave = getData['filename'];
						if (getData) {
							this.fileRef.save(
								Base64.decodeToByteArray(dataForSave),
								fileNameForSave
							);
						}
					}
				}
			}
		}

		private function fileReference_cancel(evt: Event): void {
			this.fileRef.removeEventListener(Event.CANCEL, fileReference_select);
			this.fileRef.removeEventListener(Event.SELECT, fileReference_select);
			if (this.eventListeners['oncancel']) {
				ExternalInterface.call(this.eventListeners['oncancel']);
			}
		}

		private function fileReference_select(evt: Event): void {
			this.fileRef.removeEventListener(Event.CANCEL, fileReference_select);
			this.fileRef.removeEventListener(Event.SELECT, fileReference_select);
			this.fileRef.addEventListener(Event.COMPLETE, fileReference_complete);
			if (this.eventListeners['onselect']) {
				ExternalInterface.call(this.eventListeners['onselect']);
			}
			this.fileRef.load();
		}

		private function fileReference_complete(evt: Event): void {
			this.fileRef.removeEventListener(Event.COMPLETE, fileReference_complete);
			if (this.eventListeners['onload']) ExternalInterface.call(
				this.eventListeners['onload'],
				Base64.encodeByteArray(this.fileRef["data"]),
				this.fileRef["name"],
				this.fileRef["size"],
				this.fileRef["type"]
			);
		}

		public function setParams(settings: Object): void {
			this.settings = settings;
			if (!this.settings["cursor"]) this.settings["cursor"] = "default";
			this.square.useHandCursor = (this.settings["cursor"] == "pointer");
		}

		public function setEventListener(sEventType: String, fEventHandler: String): void {
			this.eventListeners[sEventType] = fEventHandler;
		}

	}
}
