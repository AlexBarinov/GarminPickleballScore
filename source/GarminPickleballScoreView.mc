import Toybox.Activity;
import Toybox.Application;
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
    hidden var serverNumber as Number; // 1 or 2 (for doubles)
    hidden var gameType as Number; // 0 = Doubles, 1 = Singles (cached for current game)
    hidden var courtSide as Number; // 0 = left, 1 = right (actual court position for doubles)

    // Cached layout calculations
    hidden var cachedHeight as Number;
    hidden var upperScoreY as Number;
    hidden var upperLabelY as Number;
    hidden var lowerScoreY as Number;
    hidden var lowerLabelY as Number;

    hidden var scoreFont as Graphics.FontDefinition;
    hidden var labelFont as Graphics.FontDefinition;


    function initialize() {
        DataField.initialize();
        opponentScore = 0;
        playerScore = 0;
        servingSide = 0; // No serving side at start
        serverNumber = 2; // Start with server 2 (0-0-2 rule)
        courtSide = 1; // Start on right side
        gameType = Application.Properties.getValue("GameType"); // Cache game type

        // Initialize cached layout values
        cachedHeight = 0;
        upperScoreY = 0;
        upperLabelY = 0;
        lowerScoreY = 0;
        lowerLabelY = 0;

        scoreFont = Graphics.FONT_NUMBER_THAI_HOT;
        labelFont = Graphics.FONT_XTINY;

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

        if (opponentScore == 0 && playerScore == 0) {
            return;
        }

        // Use cached game type (0 = Doubles, 1 = Singles)
        var gameTypeLabel = (gameType == 0) ? "D" : "S";

        var scoreText = playerScore.format("%d") + "-" + opponentScore.format("%d") + " (" + gameTypeLabel + ")";
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
        serverNumber = 2; // Start with server 2 (0-0-2 rule)
        courtSide = 1; // Start on right side
        gameType = Application.Properties.getValue("GameType"); // Reload game type for next game

        // Request UI update to show reset scores
        WatchUi.requestUpdate();
    }

    // Calculate and cache layout positions based on screen height
    private function calculateLayout(dc as Dc, height as Number) as Void {
        var centerY = height / 2;

        var scoreHeight = dc.getFontHeight(scoreFont) / 4 * 3;
        var labelHeight = dc.getFontHeight(labelFont) / 4 * 3;

        // Calculate and cache positions for upper half (opponent)
        upperScoreY = centerY - scoreHeight / 2;
        upperLabelY = centerY - scoreHeight - labelHeight / 2;

        // Calculate and cache positions for lower half (player)
        lowerScoreY = centerY + scoreHeight / 2;
        lowerLabelY = centerY + scoreHeight + labelHeight / 2;

        // Update cached height
        cachedHeight = height;
    }

    // Handle first serve establishment
    private function handleFirstServe(tappedSide as Number, isDoubles as Boolean) as Void {
        servingSide = tappedSide;
        serverNumber = isDoubles ? 2 : 1;

        // Set court side: doubles always start right, singles based on score
        if (isDoubles) {
            courtSide = 1; // Always start on right side
        } else {
            var servingScore = (tappedSide == 1) ? opponentScore : playerScore;
            courtSide = (servingScore % 2 == 0) ? 1 : 0; // Even = right, odd = left
        }
    }

    // Handle scoring a point
    private function handleScore(tappedSide as Number) as Void {
        if (tappedSide == 1) {
            opponentScore++;
        } else {
            playerScore++;
        }
        // Switch court sides after scoring (same for doubles and singles)
        courtSide = (courtSide == 1) ? 0 : 1;
    }

    // Handle rally lost by serving side
    private function handleRallyLost(tappedSide as Number, isDoubles as Boolean) as Void {
        if (isDoubles) {
            handleDoublesRallyLost(tappedSide);
        } else {
            handleSinglesRallyLost(tappedSide);
        }
    }

    // Handle rally lost in doubles
    private function handleDoublesRallyLost(tappedSide as Number) as Void {
        if (serverNumber == 1) {
            // Switch to server 2, same team keeps serve
            serverNumber = 2;
            courtSide = (courtSide == 1) ? 0 : 1; // Switch sides
        } else {
            // Server 2 lost - side-out to other team
            servingSide = tappedSide;
            serverNumber = 1;
            courtSide = 1; // New team always starts on right side
        }
    }

    // Handle rally lost in singles
    private function handleSinglesRallyLost(tappedSide as Number) as Void {
        // Side-out to other team
        servingSide = tappedSide;
        serverNumber = 1;
        // Set court side based on new server's score
        var servingScore = (tappedSide == 1) ? opponentScore : playerScore;
        courtSide = (servingScore % 2 == 0) ? 1 : 0; // Even = right, odd = left
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var bgColor = getBackgroundColor();
        var fgColor = (bgColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

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

        // Recalculate layout if height changed
        if (height != cachedHeight) {
            calculateLayout(dc, height);
        }

        // Use cached layout values
        var centerX = width / 2;
        var centerY = height / 2;

        var textJustify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        // Clear the screen with background color
        dc.setColor(fgColor, bgColor);
        dc.clear();

        // Set color for all drawing operations
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);

        // Draw horizontal separator line
        dc.drawLine(0, centerY, width, centerY);

        // Draw "OPP" label above opponent score
        dc.drawText(centerX, upperLabelY, labelFont, "OPP", textJustify);

        // Draw opponent score in upper half
        var opponentScoreText = opponentScore.format("%d");
        dc.drawText(centerX, upperScoreY, scoreFont, opponentScoreText, textJustify);

        // Draw player score in lower half
        var playerScoreText = playerScore.format("%d");
        dc.drawText(centerX, lowerScoreY, scoreFont, playerScoreText, textJustify);

        // Draw "ME" label below player score
        dc.drawText(centerX, lowerLabelY, labelFont, "ME", textJustify);

        // Draw serving indicator (yellow circle showing court side to serve from)
        if (servingSide != 0) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            var scoreText = (servingSide == 1) ? opponentScoreText : playerScoreText;
            var scoreY = (servingSide == 1) ? upperScoreY : lowerScoreY;
            var textWidth = dc.getTextWidthInPixels(scoreText, Graphics.FONT_NUMBER_HOT);

            // Determine court side from tracked courtSide (single source of truth)
            var isRightSide = (courtSide == 1);

            // For opponent (servingSide == 1), flip the side because we view from opposite angle
            if (servingSide == 1) {
                isRightSide = !isRightSide;
            }

            var indicatorX;
            if (isRightSide) {
                indicatorX = centerX + (textWidth / 2) + 24 + 20; // radius=24, padding=20
            } else {
                indicatorX = centerX - (textWidth / 2) - 24 - 20;
            }
            
            dc.fillCircle(indicatorX, scoreY, 24);

            // Draw server number for doubles (use cached game type)
            if (gameType == 0) { // Doubles
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    indicatorX,
                    scoreY,
                    Graphics.FONT_SYSTEM_XTINY,
                    serverNumber.format("%d"),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
        }
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        var screenHeight = System.getDeviceSettings().screenHeight;

        // Determine which half was tapped (1 = opponent/upper, 2 = player/lower)
        var tappedSide = (coords[1] < screenHeight / 2) ? 1 : 2;

        // Use cached game type (0 = Doubles, 1 = Singles)
        var isDoubles = (gameType == 0);

        if (servingSide == 0) {
            // First tap - establish serve
            handleFirstServe(tappedSide, isDoubles);
        } else if (servingSide == tappedSide) {
            // Tapped the serving side - score a point
            handleScore(tappedSide);
        } else {
            // Tapped the non-serving side - rally lost
            handleRallyLost(tappedSide, isDoubles);
        }

        // Update FIT field with current score
        updateScoreField();

        // Request UI update
        WatchUi.requestUpdate();

        return true;
    }
}
