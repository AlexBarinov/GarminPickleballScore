import Toybox.Activity;
import Toybox.FitContributor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class GarminPickleballScoreView extends WatchUi.DataField {
    hidden var opponentScore as Number;
    hidden var playerScore as Number;
    hidden var scoreField as FitContributor.Field?;
    hidden var servingSide as Number; // 0 = none, 1 = opponent, 2 = player

    function initialize() {
        DataField.initialize();
        opponentScore = 0;
        playerScore = 0;
        servingSide = 0; // No serving side at start

        // Create FIT field for lap score (allocate 10 chars for "99-99")
        scoreField = createField(
            "pickleball_score",
            0,
            FitContributor.DATA_TYPE_STRING,
            {:mesgType=>FitContributor.MESG_TYPE_LAP, :units=>"", :count=>10}
        );
        scoreField.setData("");
    }

    // Update the FIT field with the current score
    private function updateScoreField() as Void {
        if(scoreField == null) {
            return;
        }
        var scoreText = playerScore.format("%d") + "-" + opponentScore.format("%d");
        scoreField.setData(scoreText);
    }

    // Called when a lap is added to the current activity
    function onTimerLap() as Void {
        // Save current score to FIT field before resetting
        updateScoreField();

        // Reset scores and serving side for new game
        opponentScore = 0;
        playerScore = 0;
        servingSide = 0;

        // Request UI update to show reset scores
        WatchUi.requestUpdate();
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var bgColor = getBackgroundColor();
        var fgColor = (bgColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

//        System.print(OBSCURE_LEFT | OBSCURE_TOP | OBSCURE_RIGHT | OBSCURE_BOTTOM);
        // Check if data field is in a quadrant (not fullscreen)
        if (getObscurityFlags() != (OBSCURE_LEFT | OBSCURE_TOP | OBSCURE_RIGHT | OBSCURE_BOTTOM)) {
            // In a quadrant layout - display message
            dc.setColor(fgColor, bgColor);
            dc.clear();
            dc.drawText(
                width / 2,
                height / 2,
                Graphics.FONT_XTINY,
                "FULLSCREEN\nREQUIRED",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            return;
        }

        // Pre-calculate common positions
        var centerX = width / 2;
        var centerY = height / 2;
        var upperY = height / 4;
        var lowerY = (height * 3) / 4;
        var textJustify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        // Clear the screen with background color
        dc.setColor(fgColor, bgColor);
        dc.clear();

        // Set color for all drawing operations
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);

        // Draw horizontal separator line
        dc.drawLine(0, centerY, width, centerY);

        // Draw opponent score in upper half
        var opponentScoreText = opponentScore.format("%d");
        dc.drawText(centerX, upperY, Graphics.FONT_NUMBER_HOT, opponentScoreText, textJustify);

        // Draw "OPPONENT" label between score and line
        dc.drawText(centerX, centerY - 25, Graphics.FONT_XTINY, "OPPONENT", textJustify);

        // Draw player score in lower half
        var playerScoreText = playerScore.format("%d");
        dc.drawText(centerX, lowerY, Graphics.FONT_NUMBER_HOT, playerScoreText, textJustify);

        // Draw "ME" label between line and score
        dc.drawText(centerX, centerY + 25, Graphics.FONT_XTINY, "ME", textJustify);

        // Draw serving indicator (yellow circle to the left of the serving player's score)
        if (servingSide != 0) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            var scoreText = (servingSide == 1) ? opponentScoreText : playerScoreText;
            var scoreY = (servingSide == 1) ? upperY : lowerY;
            var textWidth = dc.getTextWidthInPixels(scoreText, Graphics.FONT_NUMBER_HOT);
            var indicatorX = centerX - (textWidth / 2) - 24 - 10; // radius=24, padding=10
            dc.fillCircle(indicatorX, scoreY, 24);
        }
    }

    function onTap(clickEvent as WatchUi.ClickEvent) {
        var coords = clickEvent.getCoordinates();
        var screenHeight = System.getDeviceSettings().screenHeight;

        // Determine which half was tapped (1 = opponent/upper, 2 = player/lower)
        var tappedSide = (coords[1] < screenHeight / 2) ? 1 : 2;

        // Pickleball serving rules
        if (servingSide == tappedSide) {
            // Tapped the serving side - score a point, keep serving
            if (tappedSide == 1) {
                opponentScore++;
            } else {
                playerScore++;
            }
        } else {
            // Tapped the non-serving side - switch serve, no point scored
            servingSide = tappedSide;
        }

        // Update FIT field with current score
        updateScoreField();

        // Request UI update
        WatchUi.requestUpdate();
    }
}
