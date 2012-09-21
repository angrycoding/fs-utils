package {

	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.system.*;
	import flash.external.ExternalInterface;
	import com.dynamicflash.util.Base64;

	public class fsutils extends Sprite {

		private var fileRef: FileReference;
		private var eventListeners: Object = {};

		public function fsutils() {
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			this.stage.align = StageAlign.TOP_LEFT;
			var square:Sprite = new Sprite();
			square.graphics.beginFill(0x000000, 0);
			square.graphics.drawRect(0, 0, 1000, 1000);
			square.graphics.endFill();
			addChild(square);
            ExternalInterface.addCallback("addEventListener", this.setEventListener);
			square.addEventListener(MouseEvent.MOUSE_UP, function (event: MouseEvent): void { openDialog(); });
			ExternalInterface.call(this.stage.loaderInfo.parameters["onload"]);
			Security.allowDomain("*");
		}

		private function openDialog(): void {
			var dialogType: String = this.stage.loaderInfo.parameters["dialogType"];
			var fileFilterValue: String = this.stage.loaderInfo.parameters["fileFilter"];
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

		public function setEventListener(sEventType: String, fEventHandler: String): void {
			this.eventListeners[sEventType] = fEventHandler;
		}

	}
}
