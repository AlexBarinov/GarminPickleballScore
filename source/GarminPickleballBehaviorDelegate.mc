import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class PickleballBehaviorDelegate extends WatchUi.BehaviorDelegate {
    var pickleballScoreView as GarminPickleballScoreView;

    function initialize(view as GarminPickleballScoreView) {
        pickleballScoreView = view;
        BehaviorDelegate.initialize();
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
        pickleballScoreView.onTap(clickEvent);
    	return true;
    }
}