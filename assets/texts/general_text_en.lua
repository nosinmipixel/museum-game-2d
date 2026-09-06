-- assets/texts/general_text_en.lua
-- ═══════════════════════════════════════════════════════
-- 🌐 GENERAL TEXTS — ENGLISH (reference)
-- ═══════════════════════════════════════════════════════
--
--   Main file for texts: UI, intro, tasks, notifications,
--   and dialogues in English. ES is its translation; any
--   new key is added here first and then passed to ES.
--
-- License: GPL-3.0-only (See LICENSE in the root)
-- Defold version: 1.13
-- Last updated: 2026-08-15
-- ═══════════════════════════════════════════════════════

local M = {}

-- UI (Basic buttons and labels)
M.ui = {
    btn_yes           = "Yes",
    btn_no            = "No",
    btn_accept        = "Accept",
    btn_cancel        = "Cancel",
    btn_resume        = "Resume",
    btn_save          = "Save",
    btn_retry         = "Retry",
    btn_exit          = "Exit game",
    label_sound       = "Sound",
    label_bg_music    = "Background music",
    label_volume      = "Music",
    label_sfx         = "Sound Effects",
    label_pause       = "Game paused",
    label_language    = "Language",
    label_file_game   = "Save file",

    -- 🌡️ HUD temperature units (labels kept out of code). The °C/°F choice is
    --    a PLAYER PREFERENCE (global temp_units in game_state, toggle in the
    --    pause menu), not tied to language. Conversion is display-only
    --    (update_climate_texts in hud.gui_script); the simulation ALWAYS works
    --    in °C.
    temp_unit_c = "°C",
    temp_unit_f = "°F",
    label_temp_units = "Temperature units",
    label_fps = "Show FPS",
}

-- DIALOGS (Popups, feedback messages and game over)
M.dialogs = {
    confirm_reset = [[Are you sure?
This will erase all your progress
and restart the game.]],
    
    feedback_correct   = "Correct!",
    feedback_incorrect = "Incorrect",

    fight_defeat = [[You have been defeated by the museum pests.
You can try again.]],

    -- 🚗 Death by car collision (Aug 2026): the car sends taken_damage with
    --    source = "car" and the HUD discriminates the cause (player.script →
    --    show_retry_button{ cause = "car" }) to show this text instead of
    --    fight_defeat.
    car_defeat = [[You should pay attention to the traffic.
It is not safe to cross such busy streets.]],

    game_over_victory = [[You have proven to be an exceptional museum curator.
Your knowledge has helped spread Archaeology
and maintain our museum's collections.]],

    -- NPC unavailable (temporary cooldown after failing a quiz or waiting for restoration)
    npc_unavailable = "I am not available now. Come back later.",

    -- 🧑‍🤝‍🧑 Generic quiz NPC (quiz_general) with attempts EXHAUSTED
    --    (completed): no more questions left. Different from npc_unavailable,
    --    which is the temporary cooldown after failing a quiz with remaining turns.
    npc_no_more_doubts = "Thank you for your interest, I have no more questions.",

    -- 🛠️ Restorer (npc_11): no piece to restore or in cooldown
    npc_restorer_unavailable = "I am not available right now. Come back when I call you or when you have a new object to restore.",

    -- 🏆 End game: final rank label on victory screen
    victory_rank_label = "Final rank: %s",
}

-- LOCATIONS (Room, zone and door names)
M.locations = {
    welcome_museum    = [[Welcome to the Museum of
Archaeology and Prehistory]],
    room_restoration  = "Restoration Laboratory",
    room_exhibition   = "Exhibition Halls",
    room_library      = "Library",
    room_storage      = "Storerooms",
    room_intake       = "Intake Room",
    door_service      = "Service Entrance",
    door_main         = "Main Entrance",
}

-- TUTORIALS (Hints, rules, alerts and errors)
M.tutorials = {
    -- Hints
    hint_medkit      = "You can use this first-aid kit when you have some health issue.",
    hint_insecticide = "You can refill your insecticide spray when your load is not full.",
    -- 🪺 Phase 2: alert when picking up an insecticide can while at max charges
    hint_insecticide_max = "You are already carrying the maximum amount of insecticide.",
    -- 🪺 Phase 2: persistent hint while hovering an insecticide can
    --    (the poison does not refill spray: it is used on enemy nests)
    hint_hover_insecticide_poison = "Insecticide can: use it on a nest to destroy it.",
    hint_energy      = [[Here you can recover all your energy.
You will need it.]],
    hint_exhausted   = "You are exhausted! Recover energy at the vending machine.",
    
    -- Rules
    -- 🎓 One-shot educational: shown the first time an object becomes
    --    ready for a display case (EXHIBITION) to teach the mechanic.
    rule_display_case = "Remember that you must display all objects to gain experience.",
    rule_no_exp       = "You have an object in storage that needs to be displayed. If you don't display it, no objects will appear in Intake and you won't be able to increase your experience.",
    -- ⏰ The interval for this reminder lives in main/config.lua → M.balance
    --    (key reminder_no_exp), not in the texts (single source, Aug 2026).

    -- Alerts
    alert_new_material = [[Remember that you have a new object to inventory.
Go to the Intake area.]],
    hint_hover_insecticide_poison = "Extra-strong poison. Use with caution.",
    alert_no_insecticide = "You need a special poison to destroy the nest.",
    -- 🪺 Nests: alert when clicking a nest without insecticide (Phase 1, Aug 2026)
    -- ⏰ The interval for this reminder lives in main/config.lua → M.balance
    --    (key reminder_new_material), not in the texts (single source).
    -- 🏬 Storage reminder: the active object is picked up
    --    (COLLECTED, not restored) or restored but not yet deposited in the
    --    shelf (STORAGE without Timer A active) → the player must take it to
    --    the Storage area to complete the deposit.
    alert_pending_storage = [[Remember that you have an object to store.
Go to the Storage area.]],
    -- 🛠️ Restoration reminder (NEW, no quiz done): piece pending
    --    restoration and the player hasn't yet visited the restorer.
    alert_new_restoration = [[Remember that you have an object pending Restoration.
You can go to the Restoration Laboratory.]],
    -- ⏰ The interval for this reminder lives in main/config.lua → M.balance
    --    (key reminder_restorer_new), not in the texts (single source).
    -- 🛠️ Restoration reminder (RETRY after failing quiz): the player
    --    has taken the quiz, failed, and has remaining answer turns.
    alert_new_attempt_restoration = [[Have you caught up with Preventive Conservation?
If so, you can go to the Restoration Laboratory.]],
    -- ⏰ The interval for this reminder lives in main/config.lua → M.balance
    --    (key reminder_restorer_retry), not in the texts (single source).

    -- 🧑‍🤝‍🧑 NPC quiz reminder (RETRY): the player failed
    --    a generic NPC quiz and has remaining turns; %s is replaced by the
    --    localized name of the NPC (main_text → characters) when triggered.
    alert_npc_available = [[%s is available to continue their consultation.]],
    -- ⏰ The interval for this reminder lives in main/config.lua → M.balance
    --    (key reminder_npc_available), not in the texts (single source).

    -- Cat food
    hint_cat_food_pickup = "You found a can of cat food!",
    hint_cat_food_full   = "You already have a can of cat food. Use it before picking up another.",

    -- Museum cat
    hint_cat_hover      = "Meow! If you have something tasty for me, I can be your friend.",
    hint_cat_pet_start  = "You have been very kind, meow!\nI think I will keep you company for a while, meow!",

    -- Errors
    -- 🛠️ Shown when clicking on shelf/display case while the piece is still
    --    in RESTORATION (has not yet completed restoration).
    error_needs_restoration  = "You need to restore the object before depositing it.",
}

-- INVENTORY (Collectible system messages)
-- We use %s as placeholder for object names
M.inventory = {
    -- Spawn / Pickup
    new_object            = "New object available: %s!",
    all_completed         = "All objects have been exhibited!",

    -- Transitions
    pickup_restoration    = "This object needs restoration. Go to the Restoration Laboratory.",
    pickup_storage        = "Object picked up and inventoried. Go to the Storage area to place it on its corresponding shelf.",
    pickup_direct         = "Object transferred to the next phase.",

    -- Timer expired
    restoration_complete  = "Restoration completed! Place the object on a shelf.",
    storage_complete      = "Object ready for exhibition! Transfer it to a display case.",

    -- Furniture deposit
    deposited             = "Object catalogued and stored. Waiting for exhibition period...",
    -- 🖱️ Re-click on shelf with the object already deposited
    already_deposited     = "The object is already deposited on this shelf.",
    -- 🖱️ Second click: mark as ready for the showcase (%s = localized period)
    ready_for_showcase    = "Object ready for the showcase. Go to the display case of the %s period.",
    exhibited             = "%s successfully displayed!",
    completed             = "Object completed!",

    -- Interaction errors
    error_wrong_furniture = "The object is ready to be exhibited in a display case. Go to one from the correct period.",
    error_wrong_period    = "This shelf/display case does not belong to the correct period.",
    error_invalid_state   = "You cannot interact with this furniture at this time.",
    error_no_action       = "Action not available.",
    error_no_item         = "You don't have any object to deposit.",

    -- Timer B: cooldown after completion
    spawning_next         = "Object displayed! Preparing the next one...",    -- Already picked up
    already_collected     = "This object has already been collected. Follow the flow through shelves and display cases.",

    -- Timer A: progress bar for exhibition
    timer_exhibition_label = "Time until display in showcase:",

    -- 🛠️ Restorer timer (npc_11): countdown of cooldown
    -- after failing their restoration quiz.
    timer_restoration_label = "Restorer available in:",

    -- 🏷️ Period grid label in HUD (progress "displayed/total")
    period_progress_label = "Objects displayed by period",

    -- 🏷️ Furniture type names (shelf/showcase hover, text_alert)
    slot_showcase = "Display case",
    slot_shelf    = "Shelf",

    -- Period feedback on furniture hover (text_alert)
    period_correct   = "Correct period",
    period_incorrect = "Incorrect period",

    -- 🏛️ Localized period names (furniture hover, text_alert)
    periods = {
        pal = "Paleolithic",
        neo = "Neolithic",
        bro = "Bronze Age",
        ibe = "Iberian",
        rom = "Roman",
    },

    -- 🏺 Localized short names of collectible objects (alerts "%s successfully
    --    displayed!", "New object available: %s!", showcase hover).
    --    Keys = canonical string id of collectibles_data.items (NOT the numeric
    --    item_id: it is not always aligned with exhibition_text). The Spanish
    --    name in collectibles_data remains as code fallback.
    item_names = {
        pal_bifaz    = "Mousterian biface",
        pal_azagaya  = "Decorated single-bevelled spearhead",
        neo_cantaro  = "Cardial ware jar",
        neo_hacha    = "Polished stone axe",
        bro_quesera  = "Truncated-conical cheese strainer",
        bro_hacha    = "Copper axe",
        ibe_pebetero = "Iberian incense burner",
        ibe_kili     = "Kili unit",
        rom_lucerna  = "Roman oil lamp",
        rom_copa     = "Terra sigillata cup",
    },

    -- 🏆 Task progress in HUD (Tasks: 2/4)
    tasks_progress = "Tasks: %d/%d",
}

-- 🏛️ EXHIBITION (Object info panel — GUI labels. The description/period/site/
-- dimensions fields already come localized from exhibition_text_[lan].lua;
-- these are the LABELS that precede them. They used to be hardcoded in
-- Spanish in gui/exhibition.gui_script.)
M.exhibition = {
    label_object      = "Object #",
    label_description = "Description: ",
    label_period      = "Period: ",
    label_site        = "Site: ",
    label_dimensions  = "Dimensions: ",
    no_dimensions     = "Dimensions: not recorded",
}

-- 💾 SAVE GAME (pause menu — Import/Export). save_manager.lua returns neutral
-- KEYS ("exported_html5"...) and the pause menu resolves them here; the
-- messages used to be hardcoded in Spanish in save_manager.lua and showed in
-- any language (GOTCHA #37).
M.save = {
    exported_html5     = "Save exported as .json (downloaded in the browser)",
    exported_desktop   = "Save exported to: %s",
    export_error       = "Error exporting the save",
    select_file        = "Select a .json file...",
    import_ok              = "Save imported successfully",
    import_read_error      = "Could not read the save file",
    import_json_error      = "Error reading the JSON: %s",
    import_invalid_format  = "The save file is not valid",
    import_unsupported_version = "The save version is not supported",
}

-- RANKS (Player levels or ranks)
-- We use numbers as keys so we can index them directly with variables
M.ranks = {
    [1] = "1. Novice",
    [2] = "2. Senior",
    [3] = "3. Expert",
    [4] = "4. Master",
    [5] = "5. Director",
}

-- INTRO (Introduction screen)
M.intro = {
    -- A) Game title
    title = "A day at the museum",

    -- B) Input info
    inputs_info = [[CONTROLS

  —  Use the arrow keys or W,A,S,D to move
  —  Press 'P' to pause the game and open the main menu
  —  Click on objects and characters to interact with them
  —  Right-click in the direction of insects and rodents to spray insecticide against them]],

    -- B) Input info for mobile
    inputs_info_mobile = [[CONTROLS

  —  Use the joystick on the left side of the screen to move
  —  Press the button at the top right to open the main menu
  —  Press the button with the hand icon to interact with characters and objects
  —  Press the button with the spray icon to spray insecticide on insects and rodents if they are near you]],

    -- C) Intro buttons
    btn_es      = "Español",
    btn_en      = "English",
    btn_start   = "Start",
    btn_continue = "Continue",
    btn_new_game = "New Game",

    -- Save warning in browser (HTML5)
    warning_save = [[Progress is saved in this browser.
If you clear site data, you will lose your game.
Use Export/Import in the pause menu to make a backup.]],

    -- D) Introduction synopsis
    synopsis_1 = [[You are the 'novice' curator of a large Archaeology museum.
You have just started and want to show everyone your talent.
Your daily work will preserve the museum's legacy for future generations.]],

    synopsis_2 = [[There is a whole series of 'Tasks' you must do to increase your experience:

1. Organise the museum collection.
2. Assess the material condition of objects.
3. Monitor environmental conditions in the building, as well as confront the threat of pests.
4. Attend to researchers, students and the general public.

Fulfilling these tasks will allow you to achieve 'Directorship' of the museum. However, situations may arise that complicate your daily work.]],
}

return M
