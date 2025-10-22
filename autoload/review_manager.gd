extends Node

# Signals
signal review_prompt_ready  # Emitted when conditions are met to show review prompt
# Configuration - tunable parameters
# TODO: reset these settings to more appropriate numbers for release
const GAMES_BETWEEN_PROMPTS: int         = 2  # Show every X games completed (testing: 2)
const MIN_GAMES_BEFORE_FIRST_PROMPT: int = 1  # Wait for player engagement (testing: 1)
const DAYS_BETWEEN_PROMPTS: int          = 30  # Minimum days between prompts
const MAX_PROMPT_COUNT: int              = 3  # Give up after asking 3 times
# Feature flags
const ENABLE_REVIEW_PROMPTS: bool = true  # Master switch
const DEBUG_MODE: bool            = true  # Force show on desktop for testing UI
# State (persisted via SaveManager)
var games_since_last_prompt: int     = 0
var review_prompt_shown_count: int   = 0
var last_review_prompt_date: String  = ""
var user_dismissed_permanently: bool = false
var user_left_review: bool           = false
# InappReview plugin instance
var inapp_review: InappReview = null


func _ready() -> void:
    # Load saved review data
    _load_review_data()

    # Initialize InappReview plugin (only on mobile platforms)
    if _is_mobile_platform():
        _initialize_inapp_review()


func _initialize_inapp_review() -> void:
    """Initialize the InappReview plugin and connect signals"""
    inapp_review = InappReview.new()
    add_child.call_deferred(inapp_review)

    # Wait for node to be added before connecting signals
    await get_tree().process_frame

    # Connect signals
    if inapp_review:
        inapp_review.review_info_generated.connect(_on_review_info_generated)
        inapp_review.review_info_generation_failed.connect(_on_review_info_generation_failed)
        inapp_review.review_flow_launched.connect(_on_review_flow_launched)
        inapp_review.review_flow_launch_failed.connect(_on_review_flow_launch_failed)

        print("ReviewManager: InappReview plugin initialized")


func on_game_completed() -> void:
    """Called by GameManager when a game ends. Checks if review prompt should be shown."""
    if not ENABLE_REVIEW_PROMPTS:
        return

    games_since_last_prompt += 1
    _save_review_data()

    if should_show_review_prompt():
        print("ReviewManager: Conditions met for review prompt")
        review_prompt_ready.emit()


func should_show_review_prompt() -> bool:
    """Determine if all conditions are met to show the review prompt"""

    # Debug mode allows showing on desktop for testing UI
    if not DEBUG_MODE:
        # Don't show on desktop/web (only mobile platforms)
        if not _is_mobile_platform():
            return false

    # User opted out permanently or already left a review
    if user_dismissed_permanently or user_left_review:
        return false

    # Hit max prompt count
    if review_prompt_shown_count >= MAX_PROMPT_COUNT:
        return false

    # Get total games played from SaveManager
    var total_games_played = SaveManager.save_data.games_played

    # Not enough games played yet
    if total_games_played < MIN_GAMES_BEFORE_FIRST_PROMPT:
        return false

    # Haven't played enough games since last prompt
    if games_since_last_prompt < GAMES_BETWEEN_PROMPTS:
        return false

    # Check days since last prompt
    if not _enough_days_passed():
        return false

    return true


func request_review_prompt() -> void:
    """Request the native platform review flow. Called when user clicks 'Rate Now'"""
    if not _is_mobile_platform() and not DEBUG_MODE:
        print("ReviewManager: Not on mobile platform, skipping review request")
        return

    if inapp_review == null:
        push_error("ReviewManager: InappReview plugin not initialized")
        return

    print("ReviewManager: Requesting review info from platform...")

    # Mark that we're showing a prompt
    review_prompt_shown_count += 1
    games_since_last_prompt = 0
    last_review_prompt_date = _get_date_string()
    _save_review_data()

    # Step 1: Generate review info from platform
    inapp_review.generate_review_info()


func mark_review_completed() -> void:
    """Mark that the user has left a review (stop asking forever)"""
    user_left_review = true
    _save_review_data()
    print("ReviewManager: User marked as having left a review")


func dismiss_review_permanently() -> void:
    """User clicked 'Don't Ask Again' - stop showing prompts"""
    user_dismissed_permanently = true
    _save_review_data()
    print("ReviewManager: User dismissed review prompts permanently")


func dismiss_review_temporarily() -> void:
    """User clicked 'Maybe Later' - reset counter"""
    games_since_last_prompt = 0
    _save_review_data()
    print("ReviewManager: Review prompt dismissed temporarily")


# InappReview signal handlers
func _on_review_info_generated() -> void:
    """Platform successfully generated review info - now launch the review flow"""
    print("ReviewManager: Review info generated, launching review flow...")
    if inapp_review:
        inapp_review.launch_review_flow()


func _on_review_info_generation_failed() -> void:
    """Platform failed to generate review info (quota exceeded, network error, etc.)"""
    push_error("ReviewManager: Failed to generate review info")


func _on_review_flow_launched() -> void:
    """Native review dialog was successfully shown to the user"""
    print("ReviewManager: Review flow launched successfully")
    mark_review_completed()


# Note: We can't detect if user actually submitted a review
# Platform APIs don't provide that information for privacy reasons


func _on_review_flow_launch_failed() -> void:
    """Failed to launch the native review dialog"""
    push_error("ReviewManager: Failed to launch review flow")


# Helper functions
func _is_mobile_platform() -> bool:
    """Check if running on iOS or Android"""
    var os_name = OS.get_name()
    return os_name == "Android" or os_name == "iOS"


func _enough_days_passed() -> bool:
    """Check if enough days have passed since last prompt"""
    if last_review_prompt_date == "":
        return true  # Never shown before

    var today        = _get_date_string()
    var last_date    = _parse_date_string(last_review_prompt_date)
    var current_date = _parse_date_string(today)

    if last_date == null or current_date == null:
        return true  # If parsing fails, allow prompt

    # Calculate days difference
    var days_diff = _days_between_dates(last_date, current_date)
    return days_diff >= DAYS_BETWEEN_PROMPTS


func _get_date_string() -> String:
    """Get current date as YYYY-MM-DD string"""
    var date = Time.get_date_dict_from_system()
    return "%d-%02d-%02d" % [date.year, date.month, date.day]


func _parse_date_string(date_str: String) -> Dictionary:
    """Parse YYYY-MM-DD string into dictionary"""
    var parts = date_str.split("-")
    if parts.size() != 3:
        return {}

    return {
        "year": int(parts[0]),
        "month": int(parts[1]),
        "day": int(parts[2])
    }


func _days_between_dates(date1: Dictionary, date2: Dictionary) -> int:
    """Calculate days between two dates (approximate)"""
    if date1.is_empty() or date2.is_empty():
        return 0

    # Simple approximation: 30 days per month
    var days1 = date1.year * 365 + date1.month * 30 + date1.day
    var days2 = date2.year * 365 + date2.month * 30 + date2.day

    return abs(days2 - days1)


# Save/Load functions
func _load_review_data() -> void:
    """Load review data from SaveManager"""
    var data = SaveManager.load_review_data()

    if data.is_empty():
        # Use defaults (already set in variable declarations)
        return

    games_since_last_prompt = data.get("games_since_last_prompt", 0)
    review_prompt_shown_count = data.get("review_prompt_shown_count", 0)
    last_review_prompt_date = data.get("last_review_prompt_date", "")
    user_dismissed_permanently = data.get("user_dismissed_permanently", false)
    user_left_review = data.get("user_left_review", false)

    print("ReviewManager: Loaded review data - games_since_last_prompt: %d, shown_count: %d" % [games_since_last_prompt, review_prompt_shown_count])


func _save_review_data() -> void:
    """Save review data to SaveManager"""
    var data = {
                   "games_since_last_prompt": games_since_last_prompt,
                   "review_prompt_shown_count": review_prompt_shown_count,
                   "last_review_prompt_date": last_review_prompt_date,
                   "user_dismissed_permanently": user_dismissed_permanently,
                   "user_left_review": user_left_review
               }

    SaveManager.save_review_data(data)
