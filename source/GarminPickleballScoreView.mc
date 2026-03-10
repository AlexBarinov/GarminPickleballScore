import Toybox.Activity;
import Toybox.Application;
import Toybox.FitContributor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class GarminPickleballScoreView extends WatchUi.DataField {
    // Constants for serving indicator
    const INDICATOR_RADIUS = 32;
    const INDICATOR_PADDING = 20;

    // Constants for game state
    const SERVING_NONE = 0;
    const SERVING_OPPONENT = 1;
    const SERVING_PLAYER = 2;

    const COURT_LEFT = 0;
    const COURT_RIGHT = 1;

    const GAME_DOUBLES = 0;
    const GAME_SINGLES = 1;

    const SERVER_ONE = 1;
    const SERVER_TWO = 2;
    const MAX_SCORE = 99;

    hidden var opponentScore as Number;
    hidden var playerScore as Number;
    hidden var scoreField as FitContributor.Field?;
    hidden var servingSide as Number; // SERVING_NONE, SERVING_OPPONENT, or SERVING_PLAYER
    hidden var serverNumber as Number; // SERVER_ONE or SERVER_TWO
    hidden var gameType as Number; // GAME_DOUBLES or GAME_SINGLES (cached for current game)
    hidden var courtSide as Number; // COURT_LEFT or COURT_RIGHT

    // Cached layout calculations
    hidden var cachedHeight as Number;
    hidden var upperScoreY as Number;
    hidden var upperLabelY as Number;
    hidden var lowerScoreY as Number;
    hidden var lowerLabelY as Number;

    hidden var scoreFont as Graphics.FontDefinition;
    hidden var labelFont as Graphics.FontDefinition;
    hidden var indicatorFont as Graphics.FontDefinition;

    hidden var textJustify as Number;
    hidden var opponentScoreText as String;
    hidden var playerScoreText as String;


    function initialize() {
        DataField.initialize();
        opponentScore = 0;
        playerScore = 0;
        servingSide = SERVING_NONE;
        serverNumber = SERVER_TWO; // Start with server 2 (0-0-2 rule)
        courtSide = COURT_RIGHT;
        gameType = Application.Properties.getValue("GameType"); // Cache game type

        // Initialize cached layout values
        cachedHeight = 0;
        upperScoreY = 0;
        upperLabelY = 0;
        lowerScoreY = 0;
        lowerLabelY = 0;

        scoreFont = Graphics.FONT_SYSTEM_NUMBER_THAI_HOT;
        labelFont = Graphics.FONT_SYSTEM_XTINY;
        indicatorFont = Graphics.FONT_SYSTEM_TINY;

        textJustify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        opponentScoreText = "0";
        playerScoreText = "0";

        // Create FIT field for lap score
        scoreField = createField(
            "pickleball_score",
            0,
            FitContributor.DATA_TYPE_STRING,
            {:mesgType=>FitContributor.MESG_TYPE_LAP, :units=>"", :count=>15}
        );
    }

    // Update the FIT field with the current score
    private function updateScoreFit() as Void {
        if (scoreField == null) {
            return;
        }
        if (playerScore == 0 && opponentScore == 0) {
            return;
        }
        var gameTypeLabel = (gameType == GAME_DOUBLES) ? "D" : "S";
        scoreField.setData("[" + gameTypeLabel + "] " + playerScore.format("%d") + "-" + opponentScore.format("%d"));
    }

    // Called when a lap is added to the current activity
    function onTimerLap() as Void {
        // Reset scores and serving side for new game
        opponentScore = 0;
        playerScore = 0;
        opponentScoreText = "0";
        playerScoreText = "0";
        servingSide = SERVING_NONE;
        serverNumber = SERVER_TWO; // Start with server 2 (0-0-2 rule)
        courtSide = COURT_RIGHT;
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
    private function handleFirstServe(tappedSide as Number) as Void {
        servingSide = tappedSide;
        serverNumber = SERVER_TWO;
        courtSide = COURT_RIGHT; // Always start on right side
    }

    // Handle scoring a point
    private function handleScore(tappedSide as Number) as Void {
        if (tappedSide == SERVING_OPPONENT) {
            if (opponentScore < MAX_SCORE) {
                opponentScore++;
                opponentScoreText = opponentScore.format("%d");
            }
        } else {
            if (playerScore < MAX_SCORE) {
                playerScore++;
                playerScoreText = playerScore.format("%d");
            }
        }
        // Switch court sides after scoring (same for doubles and singles)
        courtSide = (courtSide == COURT_RIGHT) ? COURT_LEFT : COURT_RIGHT;
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
        if (serverNumber == SERVER_ONE) {
            // Switch to server 2, same team keeps serve
            serverNumber = SERVER_TWO;
            courtSide = (courtSide == COURT_RIGHT) ? COURT_LEFT : COURT_RIGHT; // Switch sides
        } else {
            // Server 2 lost - side-out to other team
            servingSide = tappedSide;
            serverNumber = SERVER_ONE;
            courtSide = COURT_RIGHT; // New team always starts on right side
        }
    }

    // Handle rally lost in singles
    private function handleSinglesRallyLost(tappedSide as Number) as Void {
        servingSide = tappedSide;
        var servingScore = (tappedSide == SERVING_OPPONENT) ? opponentScore : playerScore;
        courtSide = (servingScore % 2 == 0) ? COURT_RIGHT : COURT_LEFT; // Even = right, odd = left
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
                labelFont,
                "FULLSCREEN\nREQUIRED",
                textJustify
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
        dc.drawText(centerX, upperScoreY, scoreFont, opponentScoreText, textJustify);

        // Draw player score in lower half
        dc.drawText(centerX, lowerScoreY, scoreFont, playerScoreText, textJustify);

        // Draw "ME" label below player score
        dc.drawText(centerX, lowerLabelY, labelFont, "ME", textJustify);

        // Draw serving indicator (yellow circle showing court side to serve from)
        if (servingSide != SERVING_NONE) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            var scoreText = (servingSide == SERVING_OPPONENT) ? opponentScoreText : playerScoreText;
            var scoreY = (servingSide == SERVING_OPPONENT) ? upperScoreY : lowerScoreY;
            var textWidth = dc.getTextWidthInPixels(scoreText, scoreFont);

            // Determine court side from tracked courtSide (single source of truth)
            var isRightSide = (courtSide == COURT_RIGHT);

            // For opponent (servingSide == SERVING_OPPONENT), flip the side because we view from opposite angle
            if (servingSide == SERVING_OPPONENT) {
                isRightSide = !isRightSide;
            }

            var indicatorX;
            if (isRightSide) {
                indicatorX = centerX + (textWidth / 2) + INDICATOR_RADIUS + INDICATOR_PADDING;
            } else {
                indicatorX = centerX - (textWidth / 2) - INDICATOR_RADIUS - INDICATOR_PADDING;
            }

            dc.fillCircle(indicatorX, scoreY, INDICATOR_RADIUS);

            // Draw server number for doubles
            if (gameType == GAME_DOUBLES) {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    indicatorX,
                    scoreY,
                    indicatorFont,
                    serverNumber.format("%d"),
                    textJustify
                );
            }
        }
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();

        // Determine which half was tapped
        var tappedSide = (coords[1] < cachedHeight / 2) ? SERVING_OPPONENT : SERVING_PLAYER;

        // Use cached game type
        var isDoubles = (gameType == GAME_DOUBLES);

        if (servingSide == SERVING_NONE) {
            // First tap - establish serve
            handleFirstServe(tappedSide);
        } else if (servingSide == tappedSide) {
            // Tapped the serving side - score a point
            handleScore(tappedSide);
        } else {
            // Tapped the non-serving side - rally lost
            handleRallyLost(tappedSide, isDoubles);
        }

        // Update FIT field with current score
        updateScoreFit();

        // Request UI update
        WatchUi.requestUpdate();

        return true;
    }
}
