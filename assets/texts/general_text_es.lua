-- assets/texts/general_text_es.lua
-- ═══════════════════════════════════════════════════════
-- 🌐 TEXTOS GENERALES — ESPAÑOL (referencia)
-- ═══════════════════════════════════════════════════════
--
--   Archivo PRINCIPAL de textos: UI, intro, tareas, avisos
--   y diálogos en español. EN es su traducción; cualquier
--   clave nueva se añade primero aquí y luego pasa a EN.
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local M = {}

-- UI (Botones y etiquetas básicas)
M.ui = {
    btn_yes           = "Sí",
    btn_no            = "No",
    btn_accept        = "Aceptar",
    btn_cancel        = "Cancelar",
    btn_resume        = "Reanudar",
    btn_save          = "Guardar",
    btn_retry         = "Reintentar",
    btn_exit          = "Salir del juego",
    label_sound       = "Sonido",
    label_bg_music    = "Sonido de fondo",
    label_volume      = "Música",
    label_sfx         = "Efectos de sonido",
    label_pause       = "Juego en pausa",
    label_language    = "Idioma",
    label_file_game   = "Partida",

    -- 🌡️ Unidades de temperatura del HUD (etiquetas fuera del código). La
    --    elección °C/°F es una PREFERENCIA del jugador (global temp_units en
    --    game_state, toggle en el menú de pausa), no depende del idioma. La
    --    conversión es solo visual (update_climate_texts en hud.gui_script);
    --    la simulación SIEMPRE trabaja en °C.
    temp_unit_c = "°C",
    temp_unit_f = "°F",
    label_temp_units = "Unidades de temperatura",
    label_fps = "Mostrar FPS",
}

-- DIALOGS (Popups, mensajes de feedback y game over)
M.dialogs = {
    confirm_reset = [[¿Estás seguro?
Esto borrará todo tu progreso
y reiniciará el juego.]],
    
    feedback_correct   = "¡Correcto!",
    feedback_incorrect = "Incorrecto",

    fight_defeat = [[Has sido derrotado por las plagas del museo.
Puedes volver a intentarlo.]],

    -- 🚗 Muerte por atropello (Ago 2026): el coche envía taken_damage con
    --    source = "car" y el HUD discrimina la causa (player.script →
    --    show_retry_button{ cause = "car" }) para mostrar este texto en vez
    --    de fight_defeat.
    car_defeat = [[Deberías prestar atención al tráfico.
No es seguro cruzar calles tan transitadas.]],

    game_over_victory = [[Has demostrado ser un excepcional conservador de museo.
Tus conocimientos han ayudado a difundir la Arqueología 
y a mantener las colecciones de nuestro museo.]],

    -- NPC no disponible (cooldown temporal tras fallar el quiz o en espera de restauración)
    npc_unavailable = "No estoy disponible ahora. Vuelve más tarde.",

    -- 🧑‍🤝‍🧑 NPC de quiz genérico (quiz_general) con intentos AGOTADOS
    --    (completed): ya no tiene más preguntas. Distinto de npc_unavailable,
    --    que es el cooldown temporal tras fallar un quiz con turnos restantes.
    npc_no_more_doubts = "Gracias por tu interés, no tengo más dudas.",

    -- 🛠️ Restauradora (npc_11): sin pieza que restaurar o en cooldown
    npc_restorer_unavailable = "Ahora no estoy disponible. Vuelve cuando te avise o tengas un nuevo objeto que restaurar",

    -- 🏆 Fin de juego: etiqueta del rango final en la pantalla de victoria
    victory_rank_label = "Rango final: %s",
}

-- LOCATIONS (Nombres de salas, zonas y puertas)
M.locations = {
    welcome_museum    = [[Bienvenido al Museo de
Arqueología y Prehistoria]],
    room_restoration  = "Laboratorio de Restauración",
    room_exhibition   = "Salas de exposición",
    room_library      = "Biblioteca",
    room_storage      = "Almacenes",
    room_intake       = "Sala de ingreso",
    door_service      = "Entrada de servicio",
    door_main         = "Entrada principal",
}

-- TUTORIALS (Pistas, reglas, alertas y errores)
M.tutorials = {
    -- Pistas (Hints)
    hint_medkit      = "Podrás hacer uso de este botiquín cuando tengas algún problema de salud.",
    hint_insecticide = "Podrás recargar tu bote de insecticida cuando tu carga no esté completa",
    -- 🪺 Fase 2: alerta al recoger un bote de insecticida con las cargas al máximo
    hint_insecticide_max = "Ya llevas el máximo de insecticida posible",
    -- 🪺 Fase 2: hint persistente al hacer hover sobre un bote de insecticida
    --    (el veneno no rellena spray: se usa sobre los nidos de enemigos)
    hint_hover_insecticide_poison = "Bote de insecticida: úsalo sobre un nido para eliminarlo",
    hint_energy      = [[Aquí puedes recuperar toda tu energía.
La vas a necesitar]],
    hint_exhausted   = "¡Estás agotado! Recupera energía en la máquina expendedora.",
    
    -- Reglas (Rules)
    -- 🎓 One-shot educativo: se muestra la primera vez que un objeto queda
    --    listo para vitrina (EXHIBITION) para enseñar la mecánica
    rule_display_case = "Recuerda que debes exponer todos los objetos para lograr experiencia.",
    rule_no_exp       = "Tienes un objeto en almacén que necesita ser expuesto. Si no lo expones, no aparecerán objetos en Ingreso y no podrás aumentar tu experiencia.",
    -- ⏰ El intervalo de este recordatorio vive en main/config.lua → M.balance
    --    (clave reminder_no_exp), no en los textos (fuente única, Ago 2026).

    -- Alertas (Alerts)
    alert_new_material = [[Recuerda que tienes un nuevo objeto que inventariar.
Dirígete a la zona de Ingreso]],
    hint_hover_insecticide_poison = "Veneno extrafuerte. Utilízalo con prudencia.",
    alert_no_insecticide = "Puedes utilizar un veneno especial para destruir el nido.",
    -- 🪺 Nidos: alerta al clicar un nido sin insecticida (Fase 1, Ago 2026)
    -- ⏰ El intervalo de este recordatorio vive en main/config.lua → M.balance
    --    (clave reminder_new_material), no en los textos (fuente única).
    -- 🏬 Recordatorio de depósito en almacén: el objeto activo está recogido
    --    (COLLECTED, sin restaurar) o restaurado pero aún no depositado en la
    --    estantería (STORAGE sin Timer A activo) → el jugador debe llevarlo a
    --    la Zona de Almacén para completar el depósito.
    alert_pending_storage = [[Recuerda que tienes un objeto que almacenar.
Dirígete a la zona de Almacén]],
    -- 🛠️ Recordatorio de restauración (NUEVO, sin quiz hecho): pieza pendiente
    --    de restauración y el jugador aún no ha pasado por la restauradora
    alert_new_restoration = [[Recuerda que tienes un objeto pendiente de Restauración.
Puedes acercarte al Laboratorio de Restauración]],
    -- ⏰ El intervalo de este recordatorio vive en main/config.lua → M.balance
    --    (clave reminder_restorer_new), no en los textos (fuente única).
    -- 🛠️ Recordatorio de restauración (RE-INTENTO tras fallar quiz): el jugador
    --    ha hecho el quiz, ha fallado y le quedan turnos de respuesta
    alert_new_attempt_restoration = [[¿Te has puesto al día con la Conservación preventiva?
Si es así, puedes acercarte al Laboratorio de Restauración]],
    -- ⏰ El intervalo de este recordatorio vive en main/config.lua → M.balance
    --    (clave reminder_restorer_retry), no en los textos (fuente única).

    -- 🧑‍🤝‍🧑 Recordatorio de NPC de quiz disponible (RE-INTENTO): el jugador falló
    --    el quiz de un NPC genérico y le quedan turnos; %s se sustituye por el
    --    nombre localizado del NPC (main_text → characters) al dispararse
    alert_npc_available = [[%s está disponible para continuar con su consulta]],
    -- ⏰ El intervalo de este recordatorio vive en main/config.lua → M.balance
    --    (clave reminder_npc_available), no en los textos (fuente única).

    -- Comida de gato (Cat food)
    hint_cat_food_pickup = "¡Has encontrado una lata de comida para gatos!",
    hint_cat_food_full   = "Ya tienes una lata de comida de gato. Úsala antes de recoger otra.",

    -- Gato del museo (Museum cat)
    hint_cat_hover      = "¡Miau! Si tienes algo rico para mí, puedo ser tu amigo.",
    hint_cat_pet_start  = "Has sido muy amable ¡Miau!\nCreo que te acompañaré durante un rato ¡Miau!",

    -- Errores (Errors)
    -- 🛠️ Se muestra al clicar estantería/vitrina con la pieza aún en
    --    RESTORATION (todavía no ha completado la restauración)
    error_needs_restoration  = "Necesitas restaurar el objeto antes de realizar su depósito",
}

-- INVENTORY (Mensajes del sistema de coleccionables)
-- Usamos %s como placeholder para nombres de objetos
M.inventory = {
    -- Spawn / Pickup
    new_object            = "¡Nuevo objeto disponible: %s!",
    all_completed         = "¡Todos los objetos han sido exhibidos!",

    -- Transiciones
    pickup_restoration    = "Este objeto necesita restauración. Dirígete al Laboratorio de Restauración",
    pickup_storage        = "Objeto recogido e inventariado. Dirígete a la Zona de Almacén para depositarlo en su correspondiente estantería.",
    pickup_direct         = "Objeto transferido a la siguiente fase.",

    -- Timer expirado
    restoration_complete  = "¡Restauración completada! Deposita el objeto en una estantería.",
    storage_complete      = "¡Objeto listo para exhibición! Transfiérelo a una vitrina.",

    -- Depósito en mueble
    deposited             = "Objeto catalogado y almacenado. Esperando periodo de exhibición...",
    -- 🖱️ Re-clic en estantería con el objeto ya depositado (%s = periodo localizado)
    already_deposited     = "El objeto ya está depositado en esta estantería.",
    -- 🖱️ Segundo clic: marcar como listo para vitrina (%s = periodo localizado)
    ready_for_showcase    = "Objeto listo para vitrina. Dirígete a la vitrina del periodo %s.",
    exhibited             = "¡%s expuesto correctamente!",
    completed             = "¡Objeto completado!",

    -- Errores de interacción
    error_wrong_furniture = "El objeto está listo para exponerse en una vitrina. Dirígete a una que sea del periodo correcto.",
    error_wrong_period    = "Esta estantería/vitrina no pertenece al periodo correcto.",
    error_invalid_state   = "No puedes interactuar con este mueble en este momento.",
    error_no_action       = "Acción no disponible.",
    error_no_item         = "No tienes ningún objeto que depositar.",

    -- Timer B: cooldown tras completar
    spawning_next         = "¡Objeto expuesto! Preparando el siguiente...",    -- Ya recogido
    already_collected     = "Este objeto ya ha sido recogido. Sigue el flujo en estanterías y vitrinas.",

    -- Timer A: barra de progreso para exhibición
    timer_exhibition_label = "Tiempo hasta su exposición en vitrina:",

    -- 🛠️ Timer de la restauradora (npc_11): cuenta atrás del cooldown
    -- tras fallar su quiz de restauración
    timer_restoration_label = "Restauradora disponible en:",

    -- 🏷️ Etiqueta de la rejilla de periodos del HUD (progreso "exhibidas/total")
    period_progress_label = "Objetos expuestos por periodo",

    -- 🏷️ Nombres de tipos de mueble (hover de estanterías/vitrinas, text_alert)
    slot_showcase = "Vitrina",
    slot_shelf    = "Estantería",

    -- Feedback de periodo en el hover de muebles (text_alert)
    period_correct   = "Periodo correcto",
    period_incorrect = "Periodo incorrecto",

    -- 🏛️ Nombres localizados de periodos (hover de muebles, text_alert)
    periods = {
        pal = "Paleolítico",
        neo = "Neolítico",
        bro = "Bronce",
        ibe = "Ibérico",
        rom = "Romano",
    },

    -- 🏺 Nombres cortos localizados de los objetos coleccionables (alertas
    --    "¡%s expuesto!", "¡Nuevo objeto disponible: %s!", hover de vitrina).
    --    Claves = id string canónico de collectibles_data.items (NO el item_id
    --    numérico: no siempre está alineado con exhibition_text). El name de
    --    collectibles_data (español) queda como fallback en el código.
    item_names = {
        pal_bifaz    = "Bifaz musteriense",
        pal_azagaya  = "Azagaya monobiselada decorada",
        neo_cantaro  = "Cántaro cardial",
        neo_hacha    = "Hacha de piedra pulida",
        bro_quesera  = "Quesera troncocónica",
        bro_hacha    = "Hacha de cobre",
        ibe_pebetero = "Pebetero ibérico",
        ibe_kili     = "Unidad de Kili",
        rom_lucerna  = "Lucerna romana",
        rom_copa     = "Copa de terra sigillata",
    },

    -- 🏆 Progreso de tareas en el HUD (Tareas: 2/4)
    tasks_progress = "Tareas: %d/%d",
}

-- 🏛️ EXHIBICIÓN (Panel de ficha del objeto — etiquetas del GUI. Los campos
-- description/period/site/dimensions ya vienen localizados en
-- exhibition_text_[lan].lua; estas son las ETIQUETAS que las preceden.
-- Antes estaban hardcodeadas en español en gui/exhibition.gui_script.)
M.exhibition = {
    label_object     = "Objeto #",
    label_description = "Descripción: ",
    label_period     = "Periodo: ",
    label_site       = "Yacimiento: ",
    label_dimensions = "Dimensiones: ",
    no_dimensions    = "Dimensiones: No constan",
}

-- 💾 GUARDAR PARTIDA (menú de pausa — Importar/Exportar). save_manager.lua
-- devuelve CLAVES neutras ("exported_html5"...) y el menú de pausa las
-- resuelve aquí; antes los mensajes estaban hardcodeados en español en
-- save_manager.lua y se mostraban en cualquier idioma (GOTCHA #37).
M.save = {
    exported_html5     = "Partida exportada como .json (descargada en el navegador)",
    exported_desktop   = "Partida exportada en: %s",
    export_error       = "Error al exportar la partida",
    select_file        = "Selecciona un archivo .json...",
    import_ok              = "Partida importada correctamente",
    import_read_error      = "No se pudo leer el archivo de guardado",
    import_json_error      = "Error al leer el JSON: %s",
    import_invalid_format  = "El archivo de guardado no es válido",
    import_unsupported_version = "La versión de la partida no es compatible",
}

-- RANKS (Niveles o rangos del jugador)
-- Usamos los números como claves para poder indexarlos directamente con variables
M.ranks = {
    [1] = "1. Novato",
    [2] = "2. Senior",
    [3] = "3. Experto",
    [4] = "4. Master",
    [5] = "5. Director",
}

-- INTRO (Pantalla de introducción)
M.intro = {
    -- A) Título del juego
    title = "Un día en el museo",

    -- B) Inputs info
    inputs_info = [[CONTROLES

  —  Usa las teclas de dirección o W,A,S,D para moverte
  —  Tecla 'P' para pausar el juego y abrir el menú principal
  —  Haz clic sobre objetos y personajes para interactuar con ellos
  —  Haz clic secundario en la dirección de insectos y roedores para disparar spray contra ellos]],

    -- B) Inputs info
    inputs_info_mobile = [[CONTROLES

  —  Usa el joystick a la izquierda de la pantalla para moverte
  —  Pulsa el botón situado arriba a la derecha para abrir el menú principal
  —  Pulsa el botón con el icono de mano para interactuar con personajes y objetos
  —  Pulsa el botón con el icono de spray para disparar spray sobre insectos y roedores si se encuentran cerca de tí]],

    -- C) Botones de la intro
    btn_es      = "Español",
    btn_en      = "English",
    btn_start   = "Empezar",
    btn_continue = "Continuar",
    btn_new_game = "Nueva Partida",

    -- Aviso de guardado en navegador (HTML5)
    warning_save = [[El progreso se guarda en este navegador.
Si borras los datos del sitio, perderás tu partida.
Usa Exportar/Importar en el menú de pausa para hacer una copia de seguridad.]],

    -- D) Sinopsis de introducción
    synopsis_1 = [[Eres el conservador 'novato' de un gran museo de Arqueología.
Acabas de empezar y quieres demostrar a todo el mundo tu talento.
Tu labor diaria preservará el legado del museo para las futuras generaciones.]],

    synopsis_2 = [[Existen toda una serie 'Tareas' que debes hacer para aumentar tu experiencia:

1. Organizar la colección del museo.
2. Evaluar la condición material de los objetos.
3. Vigilar las condiciones ambientales en el edificio, así como enfrentar la amenaza de plagas.
4. Atender a investigadores, estudiantes y público general.

El cumplimiento de estas tareas te permitirá alcanzar la 'Dirección' del museo. Sin embargo, pueden surgir situaciones que compliquen tu trabajo diario.]],
}

return M
