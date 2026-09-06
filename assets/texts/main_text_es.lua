-- assets/texts/main_text_es.lua
-- ═══════════════════════════════════════════════════════
-- 🧑 TEXTOS PRINCIPALES — ESPAÑOL (referencia)
-- ═══════════════════════════════════════════════════════
--
--   Nombres y spine_id de personajes (player, npc_01..13)
--   y textos principales del juego en español. Archivo de
--   referencia (ES); existe equivalente en EN.
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

return {
  characters = {
    player = {
      name = "Conservador",
      spine_id = "player"
    },
    npc_01 = {
      name = "Anciano",
      spine_id = "npc_01"
    },
    npc_02 = {
      name = "Investigadora universitaria",
      spine_id = "npc_01"
    },    
    npc_03 = {
      name = "Miembro de Centro Excursionista",
      spine_id = "npc_03"
    },
    npc_04 = {
      name = "Aficionada numismática",
      spine_id = "npc_04"
    },
    npc_05 = {
      name = "Alumna de primaria",
      spine_id = "npc_05"
    },
    npc_06 = {
      name = "Cronista local",
      spine_id = "npc_06"
    },
    npc_07 = {
      name = "Periodista",
      spine_id = "npc_07"
    },
    npc_08 = {
      name = "Coleccionista privado",
      spine_id = "npc_08"
    },
    npc_09 = {
      name = "Alumna de instituto",
      spine_id = "npc_09"
    },
    npc_10 = {
      name = "Turista",
      spine_id = "npc_10"
    },
    npc_11 = {
      name = "Restauradora",
      spine_id = "npc_11"
    },
    npc_12 = {
      name = "Bibliotecaria",
      spine_id = "npc_12"
    },
    npc_13 = {
      name = "Guardia de seguridad",
      spine_id = "npc_13"
    }
  },
  narrative = {
    npc_01_attempt1 = {
      dialog_1 = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "Buenos días, he venido a depositar una pieza que ha estado en mi familia durante años.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Ummm. ¡Vaya! ¡Qué interesante! \n¿Podría ver la pieza?",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "¡Claro! Aquí la tiene.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "¿Por cierto, podría decirme qué objeto es?\nParece usted muy joven y no sé si puede hacerse cargo de algo tan valioso.",
        start_quiz = "pool_1",
        what_question = "p1",
        is_quiz = true
      },
      failure = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "¡Jovenzuelo!\nNo parece usted muy avispado.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "Creo que seguiré conservando esta joya en mi familia.\nUna visita a la Biblioteca no le vendría mal.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "¡Vaya! Me sorprenden sus conocimientos.\nCreo que puedo confiar en usted y depositar este magnífico objeto en su museo.",
        next = "end_success"
      }
    },
    npc_01_attempt2 = {
      dialog_1 = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "Joven, he vuelto de nuevo.\nQuería volver a darle la oportunidad para depositar este objeto en su museo.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "No hay problema.\nAhora sin duda podré identificarlo.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "Ya veremos\n¿Sabe ya qué objeto es?",
        start_quiz = "pool_1",
        what_question = "p1",
        is_quiz = true
      },
      failure = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "¡No veo mejoras en su conocimiento desde la última vez!\nSeguiré conservando esta joya en mi familia.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "¡Qué gran avance!\n¡Valoro su esfuerzo!\nCreo que, sin duda, puedo depositar este magnífico objeto en su museo.",
        next = "end_success"
      }
    },
    npc_01_attempt3 = {
      dialog_1 = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "Quería volver a darle una última oportunidad para depositar aquí el objeto que poseo.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Es una gran responsabilidad.\nDebo identificarlo.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "Eso espero\n¿Sabe ya qué objeto es?",
        start_quiz = "pool_1",
        what_question = "p1",
        is_quiz = true
      },
      failure = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "¡Usted no reúne las condiciones para custodiar este objeto!\nEste objeto permanecerá definitivamente en mi familia.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "¡Qué gran avance!\n¡Valoro su esfuerzo!\nCreo que, sin duda, puedo depositar este legado en su museo.",
        next = "end_success"
      }
    },
    npc_02_attempt1 = {
      dialog_1 = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Hola, estoy aquí porque necesito información para realizar un trabajo de investigación sobre industria lítica del Paleolítico.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Es un período fascinante, el más largo de la existencia humana.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Sí. Por eso elegí esta especialidad, aunque todavía me cuesta datar algunos materiales.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "¿Podría decirme a qué periodo de la Prehistoria pertenece este bifaz?",
        start_quiz = "pool_1",
        what_question = "p2",
        is_quiz = true
      },
      failure = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "¡Vaya! Pensaba que usted, como conservador, me ayudaría a fechar correctamente esta pieza.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Aunque seguramente encontrará en la Biblioteca la información necesaria para documentar este tipo de objetos.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Es una suerte contar con la ayuda de verdaderos especialistas como usted.\nEstoy realmente agradecida.",
        next = "end_success"
      }
    },
    npc_02_attempt2 = {
      dialog_1 = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "He vuelto al museo para seguir con el estudio de materiales.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Estaré encantado de ayudarle en lo que necesite.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Por cierto, ¿ha averiguado ya a qué periodo corresponde el bifaz que vimos?",
        start_quiz = "pool_1",
        what_question = "p2",
        is_quiz = true
      },
      failure = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "En fin. Su fuerte no es la datación de la industria lítica.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Perfecto. Veo que ha hecho usted los deberes.",
        next = "end_success"
      }
    },
    npc_02_attempt3 = {
      dialog_1 = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Yo, por mi parte, continúo con mi trabajo de investigación.\n¿Ha avanzado usted en la datación de industria lítica?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Continuo avanzando con mis conocimientos.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "¿Sabría decirme a qué periodo de la Prehistoria pertenece este bifaz?",
        start_quiz = "pool_1",
        what_question = "p2",
        is_quiz = true
      },
      failure = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Vaya. Ya no volveré a insistirle más con esta cuestión.\nNo quisiera ponerle en evidencia frente a otros colegas.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Perfecto. Veo que ha hecho usted los deberes.",
        next = "end_success"
      }
    },
    npc_03_attempt1 = {
      dialog_1 = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "¡Buenos días! Pertenezco al Centro Excursionista Local.\nEstamos preparando una pequeña exposición sobre tecnología en la Prehistoria.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Me parece una iniciativa magnífica.\nLa divulgación de la Prehistoria es fundamental.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "¡Claro!\n Pero queremos la máxima rigurosidad y tenemos dudas sobre algunos aspectos técnicos de ese período.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "¿Podría indicarnos cuál de estos materiales no se utilizaba en la Prehistoria?",
        start_quiz = "pool_1",
        what_question = "p3",
        is_quiz = true
      },
      failure = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "Vaya, me temo que esa respuesta no coincide con otras consultas que hemos realizado.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "Quizás salgamos de dudas si consulta los fondos de su biblioteca.\nEn cualquier caso volveré para ver si puede arrojar luz sobre este asunto.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "¡Perfecto! Eso confirma lo que habíamos leído.\nAhora nuestra exposición ganará mucho en rigor.\nSe lo agradezco mucho.",
        next = "end_success"
      }
    },
    npc_03_attempt2 = {
      dialog_1 = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "He vuelto, espero que haya podido averiguar algo sobre el asunto del que hablamos.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Sí, he consultado algunas publicaciones sobre tecnología en la Prehistoria.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "Me alegra oírlo. Entonces, ¿ha podido confirmar cuál de esos materiales no se utilizaba en la Prehistoria?",
        start_quiz = "pool_1",
        what_question = "p3",
        is_quiz = true
      },
      failure = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "Lamento decirle que no parece ser la respuesta correcta.\nVolveré para dilucidar esta cuestión de una vez por todas.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "¡Así se hace! Veo que se ha puesto las pilas.\nEsta confirmación nos será de gran ayuda.",
        next = "end_success"
      }
    },
    npc_03_attempt3 = {
      dialog_1 = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "Última visita para resolver la duda que nos atañe.\n¿Trae la lección aprendida?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Ya lo creo. Esta vez lo tengo claro.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "Me alegra oírlo.\n¿Entonces ha podido confirmar cuál de estos materiales no se utilizaba en la Prehistoria?",
        start_quiz = "pool_1",
        what_question = "p3",
        is_quiz = true
      },
      failure = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "Lo siento pero creo que, incluso nosotros, tenemos más claros algunos conceptos básicos.\nEn cualquier caso, ya no le robaremos más tiempo.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "¡Por fin! Menos mal.\nAhora sí podemos ofrecer con más seguridad el contenido de nuestra exposición.",
        next = "end_success"
      }
    },
    npc_04_attempt1 = {
      dialog_1 = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "Buenas tardes. Soy coleccionista y me interesa especialmente la numismática ibérica.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Es un campo apasionante.\nLas monedas ibéricas están llenas de pequeños detalles.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "Así es.\nEstoy inventariando mi colección y la identificación de los reversos es clave para una correcta catalogación.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "Por cierto, ¿podría decirme cuál es el diseño más habitual en el reverso de las monedas ibéricas como esta unidad de Kelin?",
        start_quiz = "pool_1",
        what_question = "p4",
        is_quiz = true
      },
      failure = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "Hmm, no estoy segura de que sea correcto.\nHe consultado muchos catálogos y había llegado a otra conclusión.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "Seguro que le vendría bien revisar alguna monografía especializada en acuñaciones ibéricas.\nVolveré más adelante.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "¡Exactamente! Un jinete con lanza.\nEs un placer hablar con un profesional que domina este tema.",
        next = "end_success"
      }
    },
    npc_04_attempt2 = {
      dialog_1 = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "He vuelto para seguir estudiando las piezas de su exposición.\n¿Ha podido profundizar en mi pregunta?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "He repasado algunos de nuestros fondos y creo estar en condiciones de responder a ella.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "¿Y bien? ¿Cuál es el reverso más típico de las monedas ibéricas?",
        start_quiz = "pool_1",
        what_question = "p4",
        is_quiz = true
      },
      failure = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "Vaya, me temo que su respuesta no coincide con mi investigación.\nSigo confiando más en mis catálogos.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "¡Bravo! Ahora está en lo cierto.\nMe alegra que haya podido confirmarlo.",
        next = "end_success"
      }
    },
    npc_04_attempt3 = {
      dialog_1 = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "Es la última vez que vengo a consultarle.\nEspero que ahora lo tenga claro.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Esta vez tengo absoluta certeza.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "¿Cuál es el diseño más habitual en el reverso de las monedas ibéricas?",
        start_quiz = "pool_1",
        what_question = "p4",
        is_quiz = true
      },
      failure = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "Definitivamente, tendrá que especializarse más en el campo de la numismática.\nYo seguiré con mis libros.\nBuenos días.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "¡Magnífico! Un jinete.\nYa puede considerarse un experto.\nGracias por su ayuda.",
        next = "end_success"
      }
    },
    npc_05_attempt1 = {
      dialog_1 = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "Hola, señor conservador.\nEstamos haciendo un trabajo en el cole sobre el Neolítico.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "¡Hola! Qué bien, me encanta que los más pequeños se interesen por la Prehistoria.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "Sí, y mi profe nos ha dicho que miremos bien las piedras.\nHay piedras muy lisas, y otras que parecen más ásperas.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "¿Sabe usted qué técnica para el trabajo de la piedra surge durante el Neolítico y la deja así de suave?",
        start_quiz = "pool_1",
        what_question = "p5",
        is_quiz = true
      },
      failure = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "¡Anda! Pues creo que mi profe nos dijo algo diferente.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "A lo mejor si mira en esos libros tan gordos que tiene en la Biblioteca, lo encuentra.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "¡Sí, sí, el pulimentado! ¡Lo sabía!\n¡Muchas gracias!\nLe contaré a la profe lo mucho que saben en este museo.",
        next = "end_success"
      }
    },
    npc_05_attempt2 = {
      dialog_1 = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "He vuelto con mi cuaderno.\n¿Ha encontrado ya más información sobre esas piedras tan lisas?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Sí, he estado investigando un poco para ti.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "¿Y? ¿Cómo se llama esa técnica del trabajo de la piedra que surgió durante el Neolítico?",
        start_quiz = "pool_1",
        what_question = "p5",
        is_quiz = true
      },
      failure = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "Uy, no. Creo que se ha confundido.\nNo me suena que mi profe hablara nada sobre eso.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "¡Lo ha conseguido! ¡Genial!\nAhora sí que mi profe me pondrá un sobresaliente.",
        next = "end_success"
      }
    },
    npc_05_attempt3 = {
      dialog_1 = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "Es la última vez que puedo venir.\nSe me acaba el tiempo para hacer el trabajo del cole.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "¡Cómo no me voy a acordar!",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "¿Se acuerda del nombre de esa técnica del trabajo de la piedra que surge durante el Neolítico?",
        start_quiz = "pool_1",
        what_question = "p5",
        is_quiz = true
      },
      failure = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "Vaya, parece que es muy difícil.\nNo se preocupe, yo mismo se lo explicaré algún día cuando lo aprenda mejor.\n¡Adiós!",
        next = "end_fail"
      },
      success = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "¡Bien! ¡Pulimentado! Eso es.\nAhora sí que parece un auténtico conservador.\n¡Gracias!",
        next = "end_success"
      }
    },
    npc_06_attempt1 = {
      dialog_1 = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "Buenos días. Soy el cronista oficial de un pueblo cercano y estoy documentando nuestro pasado más remoto.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Es un placer.\nEl estudio de la historia local es realmente importante como base para comprender fenómenos más generales.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "Así es.\nY me gustaría ahondar en algunos aspectos de la vida cotidiana de nuestros antepasados neolíticos, 'hasta sus entrañas', como se suele decir.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "En concreto, para ser rigurosos, ¿podría decirme cuál de estos elementos no se utilizaba en la decoración de la cerámica neolítica?",
        start_quiz = "pool_1",
        what_question = "p6",
        is_quiz = true
      },
      failure = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "Hmm, me temo que sus fuentes no son del todo precisas.\nEso no concuerda con lo que he podido leer.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "Le aconsejo que consulte su Biblioteca.\nIncluso en la nuestra tenemos algunas publicaciones muy interesantes sobre el particular.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "¡Exacto! Me complace ver que está bien documentado.\nSerá un placer volver para compartir conocimientos.",
        next = "end_success"
      }
    },
    npc_06_attempt2 = {
      dialog_1 = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "He regresado para cotejar más datos.\n¿Ha tenido tiempo de revisar mi pregunta?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Sí, he podido consultar algunos documentos.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "¿Y? ¿Ha dado con el elemento anacrónico?\n¿Cuál de estos utensilios no se utilizaba en la decoración de la cerámica neolítica?",
        start_quiz = "pool_1",
        what_question = "p6",
        is_quiz = true
      },
      failure = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "Lamento decirle que persiste en el error.\nComo cronista, debo ser inflexible con este tipo de cuestiones.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "¡Correcto! Veo que ha aprovechado el tiempo.\nTome nota para futuras consultas.",
        next = "end_success"
      }
    },
    npc_06_attempt3 = {
      dialog_1 = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "Una última consulta para salir de dudas.\nEspero que la respuesta sea ahora la definitiva.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Tengo la confianza de que así sea.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "¿Ha dado ya con el elemento anacrónico?\n¿Cuál de estos utensilios no se utilizaba en la decoración de la cerámica neolítica?",
        start_quiz = "pool_1",
        what_question = "p6",
        is_quiz = true
      },
      failure = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "Definitivamente, comunicaré a otros colegas que este museo no es una fuente confiable para realizar determinadas consultas técnicas.\nQue tenga un buen día.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "¡Por fin! La espátula de cobre, efectivamente.\nHa sido capaz de sobreponerse a mis inquisitivas preguntas.\nGracias.",
        next = "end_success"
      }
    },
    npc_07_attempt1 = {
      dialog_1 = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Buenos días, soy un periodista de la revista 'Historia Viva'.\nEstoy preparando un reportaje sobre avances tecnológicos en la antigüedad.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "¡Ah, bienvenido! La prensa especializada siempre es una gran aliada.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Gracias.\nPara el artículo, es crucial destacar los saltos tecnológicos.\nEste hacha de cobre marca un antes y un después, pues el bronce supuso una auténtica revolución.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Para contextualizar, ¿sabría decirme qué técnica aparece en la Edad del Bronce?",
        start_quiz = "pool_1",
        what_question = "p7",
        is_quiz = true
      },
      failure = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Mmm, ese dato no coincide con la información que tenía.\nTendré que contrastarla con otras fuentes para no publicar ningún error.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Quizá tendré que buscar a alguien que controle más sobre metalurgia antigua.\nLe sugiero que usted también se ponga al día.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "¡La fundición! Exacto.\nYa veo el titular.\nPerfecto para mi reportaje.\nTendrá una mención especial.",
        next = "end_success"
      }
    },
    npc_07_attempt2 = {
      dialog_1 = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "He vuelto para ampliar información sobre otros temas,\npero ya que estoy aquí, me gustaría saber si ha averiguado la cuestión del otro día.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Creo que ahora lo tengo más claro.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "¿Cuál es la técnica que aparece en la Edad del Bronce?",
        start_quiz = "pool_1",
        what_question = "p7",
        is_quiz = true
      },
      failure = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Ummm, seguimos sin tener claro el dato\ny no puedo arriesgarme a publicar información incorrecta.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "¡Eso es! ¡Fundición!\n¡Ya puedo confirmar este dato!",
        next = "end_success"
      }
    },
    npc_07_attempt3 = {
      dialog_1 = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Una última oportunidad para confirmar el dato clave. ¿Podrá usted finalmente ayudarme?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Esta vez estoy seguro.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "¿Cuál es la técnica metalúrgica que surge en la Edad del Bronce?",
        start_quiz = "pool_1",
        what_question = "p7",
        is_quiz = true
      },
      failure = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Definitivamente, buscaré a otro especialista.\nGracias de todos modos.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "¡Correcto! La fundición.\nMe alegra que al final haya podido aclararlo.\nSerá de gran ayuda.",
        next = "end_success"
      }
    },
    npc_08_attempt1 = {
      dialog_1 = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Buenas tardes.\nPoseo una colección de cerámica antigua bastante respetable,\ny a veces acudo a museos como el suyo para... contrastar piezas.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Existen colecciones particulares muy interesantes.\nMuchas de sus piezas pueden tener gran valor científico,\naunque la mayoría haya perdido su contexto arqueológico.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Bueno.\nYo me considero un entendido.\nPor ejemplo, tengo una pieza que, según mi criterio, es una olla de la Edad del Bronce.\nPero un rival... digo, otro coleccionista, insiste en que no puede ser de esa época.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Para zanjar la cuestión, dígame: ¿Cuál de estas formas cerámicas no es propia de la Edad del Bronce?",
        start_quiz = "pool_1",
        what_question = "p8",
        is_quiz = true
      },
      failure = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "¡Ja! Justo lo que pensaba.\nParece que su conocimiento de las formas cerámicas no es muy profundo.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Debería visitar alguna colección privada de prestigio.\nLlegamos hasta donde no alcanzan estas colecciones públicas.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "¡Vaya! Me sorprende gratamente.\nEfectivamente, el cálatos es muy posterior.\nQuizás le sorprenda saber que también tengo alguno de ellos.",
        next = "end_success"
      }
    },
    npc_08_attempt2 = {
      dialog_1 = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "He regresado.\nHe estado pensando en nuestra anterior conversación y quería darle una segunda oportunidad.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Mi respuesta será más acertada esta vez, estoy seguro.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Veamos.\n¿Cuál de estas formas cerámicas no es propia de la Edad del Bronce?",
        start_quiz = "pool_1",
        what_question = "p8",
        is_quiz = true
      },
      failure = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Increíble.\nNo sé si me toma el pelo.\nEl personal de este museo no está a la altura de mi colección.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Umm, veo que ha aprendido la lección.\nBien por usted.\nPor fin demuestra algo de buen criterio.",
        next = "end_success"
      }
    },
    npc_08_attempt3 = {
      dialog_1 = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Última visita.\nEspero que 'a la tercera sea la vencida'.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Definitivamente tengo la respuesta correcta.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Veremos.\n¿Cuál de estas formas cerámicas no es propia de la Edad del Bronce?",
        start_quiz = "pool_1",
        what_question = "p8",
        is_quiz = true
      },
      failure = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "No.\nDefinitivamente, no sé cómo hacen las cosas aquí.\nPrefiero confiar en mi propio criterio.\nBuenos días y hasta nunca.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Correcto.\nEl cálatos.\nMe alegra que al final haya llegado a la conclusión adecuada.",
        next = "end_success"
      }
    },
    npc_09_attempt1 = {
      dialog_1 = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Hola, buenas.\nDisculpe, somos de 1º de la ESO y tenemos que hacer un trabajo sobre Roma.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "¡Hola! Claro, preguntad lo que necesitéis.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Genial, gracias.\nEsta vasija nos llama mucho la atención porque tiene un brillo y un color super guay.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "¿Podría decirnos con qué nombre es conocido este tipo de cerámica tan bonita?",
        start_quiz = "pool_1",
        what_question = "p9",
        is_quiz = true
      },
      failure = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Uy, me ha parecido ver que en nuestro libro de texto aparece un nombre distinto.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Tenemos que volver por aquí, así que podría buscarlo en alguno de esos grandes catálogos que tienen.\nO en internet.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "¡Terra sigillata! ¡Eso, eso!\n¡Muchas gracias!\nLa profesora nos pondrá un diez seguro.",
        next = "end_success"
      }
    },
    npc_09_attempt2 = {
      dialog_1 = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Hola, hemos vuelto.\n¿Se acuerda de nosotras?\n¿Ha mirado lo del nombre de la cerámica?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "¡Claro que me acuerdo! Sí, he consultado en catálogos de cerámica romana.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "¿Sí? ¿Con qué nombre es conocido este tipo de cerámica?",
        start_quiz = "pool_1",
        what_question = "p9",
        is_quiz = true
      },
      failure = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Uf, me parece que sigue sin ser eso.\nNo sé si preguntarle al otro profesor de historia del 'insti'.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "¡Sí! ¡Lo sabía!\nYa lo ha recordado.\nGracias por todo.",
        next = "end_success"
      }
    },
    npc_09_attempt3 = {
      dialog_1 = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Hola de nuevo.\nEs la última vez que podemos pasar por aquí.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Esta vez tendréis el nombre correcto.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "¿Con qué nombre es conocido este tipo de cerámica?",
        start_quiz = "pool_1",
        what_question = "p9",
        is_quiz = true
      },
      failure = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Bueno, no pasa nada.\nTodos nos equivocamos.\nGracias igualmente.\n¡Adiós!",
        next = "end_fail"
      },
      success = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "¡Terra sigillata! ¡Confirmado y apuntado!\n¡Muchas gracias por su ayuda!",
        next = "end_success"
      }
    },
    npc_10_attempt1 = {
      dialog_1 = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "¡Hola! Disculpe, ¡este museo es maravilloso!\nY me fascina especialmente la época romana.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "¡Gracias! Me alegra que le guste.\n¿Necesita ayuda con algo?",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "¡Oh, sí! Este objeto parece tan... avanzado para su tiempo.\nCreo saber lo que es y me gustaría mencionarlo en mi blog de viajes.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "En esta guía dice que se trata de una estátera romana.\n¿Pero sabe usted para qué se utilizaban estos objetos?",
        start_quiz = "pool_1",
        what_question = "p10",
        is_quiz = true
      },
      failure = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "Oh, pensaba que era para otra cosa.\nHe visto un vídeo en Youtube que lo relacionaba con algo diferente.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "Quizás pueda consultarlo en su base de datos.\nEstoy segura de que encontrará la información correcta.\nYa volveré más adelante por aquí.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "¡Sí! ¡Para pesar objetos! Eso es lo que pensaba.\n¡Perfecto!\nAhora tengo total seguridad y podré hablar de ella sin problemas.\n¡Muchas gracias!",
        next = "end_success"
      }
    },
    npc_10_attempt2 = {
      dialog_1 = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "¡Hola de nuevo! He vuelto para ver esa preciosa estátera.\nEs una pieza cautivadora.\n¿Ha averiguado más sobre su uso?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "He estado investigando un poco, sí.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "¡Genial! Entonces, ¿para qué servía una estátera?",
        start_quiz = "pool_1",
        what_question = "p10",
        is_quiz = true
      },
      failure = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "Mmm, no estoy segura de que sea correcto.\nYo también he consultado información y tengo la impresión de que anda algo desencaminado.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "¡Oh, sí! Creo que por fin estamos de acuerdo.\nEra para pesar.\nGracias por comprobarlo y poder confirmarlo.",
        next = "end_success"
      }
    },
    npc_10_attempt3 = {
      dialog_1 = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "¡Última visita! Debo volver a mi país, aunque espero que tenga la respuesta definitiva para los lectores de mi blog.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Ahora no me cabe ninguna duda.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "¡Genial! Entonces, ¿para qué servía una estátera?",
        start_quiz = "pool_1",
        what_question = "p10",
        is_quiz = true
      },
      failure = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "Diría que su información no concuerda con la mía.\nTengo muchas dudas y no sé si finalmente escribiré sobre este objeto en mi blog.\nGracias de todos modos.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "¡Excelente! 'Se usaba para pesar objetos'.\n¡Perfecto!\nA mis seguidores les encantará este detalle.\n¡Ha sido de gran ayuda!",
        next = "end_success"
      }
    },
    npc_11_attempt1 = {
      dialog_1 = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "¡Vaya!\n¡Tú por aquí!",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Hola. Me gustaría que analizaras este objeto para comprobar si necesita alguna intervención",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "¡Claro! Lo haré encantada...\nPero antes tendrás que resolver una pequeña pregunta",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "¿Cuál es el objetivo principal de la conservación preventiva?",
        start_quiz = "pool_2",
        what_question = "q1_pool2",
        is_quiz = true
      },
      failure = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "¡Oh, vaya!\nMe parece que andas algo perdido",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "Te haré sufrir un poco.\nYa te avisaré para que vuelvas a pasar por aquí",
        next = "end_fail"
      },
      success = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "¡Correcto! La conservación preventiva no se centra en intervenir directamente en el objeto, sino en protegerlo controlando su entorno",
        next = "end_success"
      }
    },
    npc_11_attempt2 = {
      dialog_1 = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "¡Hola de nuevo!, ¿Has hecho tus deberes?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Sí. He estado investigando un poco",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "¡Genial! Entonces, ¿Cuál es el objetivo principal de la conservación preventiva?",
        start_quiz = "pool_2",
        what_question = "q1_pool2",
        is_quiz = true
      },
      failure = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "Ummm, esta pieza tendrá que esperar un poco más.\nTe avisaré de nuevo",
        next = "end_fail"
      },
      success = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "¡Correcto! La conservación preventiva no se centra en intervenir directamente en el objeto, sino en protegerlo controlando su entorno",
        next = "end_success"
      }
    },
    npc_11_attempt3 = {
      dialog_1 = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "¡Otra vez por aquí!, ¿Podrás contestar correctamente?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Sin duda. Definitivamente tengo la respuesta correcta",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "¡Perfecto! Dime, ¿Cuál es el objetivo principal de la conservación preventiva?",
        start_quiz = "pool_2",
        what_question = "q1_pool2",
        is_quiz = true
      },
      failure = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "En fin, no me queda otra que aceptar la pieza para su análisis.\nPero tus conocimientos sobre conservación no van a aumentar",
        next = "end_fail"
      },
      success = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "¡Correcto! La conservación preventiva no se centra en intervenir directamente en el objeto, sino en protegerlo controlando su entorno",
        next = "end_success"
      }
    },
    npc_12_talk_1 = {
      dialog_1 = {
        speaker = "npc_12",
        anim = "talk",
        sound = "/npc_12#npc_12",
        text = "Buenos días. ¿Vienes buscando información específica sobre Arqueología?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Pues sí. El conocimiento no ocupa lugar.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_12",
        anim = "talk",
        sound = "/npc_12#npc_12",
        text = "El tamaño de estas librerías parece contradecir esa afirmación. Aunque seguro que en ellas encontrarás la respuesta que buscas.",
        next = "end_talk"
      }
    },
    npc_12_talk_2 = {
      dialog_1 = {
        speaker = "npc_12",
        anim = "talk",
        sound = "/npc_12#npc_12",
        text = "¿Qué tal estás? ¿Necesitas consultar algo de nuevo?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Sí. Necesito ampliar mis conocimientos.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_12",
        anim = "talk",
        sound = "/npc_12#npc_12",
        text = "Perfecto. Te noto muy motivado. Sumérgete en la lectura de los libros.",
        next = "end_talk"
      }
    },
    npc_13_talk_1 = {
      dialog_1 = {
        speaker = "npc_13",
        anim = "talk",
        sound = "/npc_13#npc_13",
        text = "Buenos días, ¿Hay algún problema en el Museo?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "No. Todo está bastante tranquilo.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_13",
        anim = "talk",
        sound = "/npc_13#npc_13",
        text = "Perfecto. Tampoco hay grandes novedades por aquí.",
        next = "end_talk"
      }
    },
    npc_13_talk_2 = {
      dialog_1 = {
        speaker = "npc_13",
        anim = "talk",
        sound = "/npc_13#npc_13",
        text = "Buenos días, ¿Qué tal va todo?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Bien, bien. El día está siendo tranquilo.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_13",
        anim = "talk",
        sound = "/npc_13#npc_13",
        text = "Me alegro. Que siga así.",
        next = "end_talk"
      }
    }
  },
  quizzes = {
    pool_1 = {
      config = {
        maximum_attempts = 3,
        total_questions = 10
      },
      questions = {
        {
          id = "p1",
          image = "Q1_Barniz_Negro_855-9",
          text = "¿Qué objeto es este?",
          options = {
            {
              label = "Copa caliciforme",
              is_correct = false
            },
            {
              label = "Urna cineraria",
              is_correct = false
            },
            {
              label = "Jarra de barniz negro",
              is_correct = true
            }
          }
        },
        {
          id = "p2",
          image = "Q2_63351_bifaz",
          text = "¿A qué periodo de la Prehistoria pertenece el bifaz?",
          options = {
            {
              label = "Epipaleolítico",
              is_correct = false
            },
            {
              label = "Neolítico",
              is_correct = false
            },
            {
              label = "Paleolítico",
              is_correct = true
            }
          }
        },
        {
          id = "p3",
          image = "Q3_Materiales_Paleo",
          text = "¿Cuál de estos materiales no se utilizaba en la Prehistoria?",
          options = {
            {
              label = "Hueso",
              is_correct = false
            },
            {
              label = "Mármol",
              is_correct = true
            },
            {
              label = "Sílex",
              is_correct = false
            }
          }
        },
        {
          id = "p4",
          image = "Q4_Coins_Iber",
          text = "¿Cuál es el diseño más habitual en el reverso de las monedas ibéricas?",
          options = {
            {
              label = "Un jinete",
              is_correct = true
            },
            {
              label = "Un buey",
              is_correct = false
            },
            {
              label = "Un león",
              is_correct = false
            }
          }
        },
        {
          id = "p5",
          image = "Q5_Tecnica_Neo",
          text = "¿Qué técnica para el trabajo de la piedra surge durante el Neolítico?",
          options = {
            {
              label = "Percusión directa",
              is_correct = false
            },
            {
              label = "Pulimentado",
              is_correct = true
            },
            {
              label = "Talla por presión",
              is_correct = false
            }
          }
        },
        {
          id = "p6",
          image = "Q6_Ceram_Neo",
          text = "¿Cuál de estos objetos no se utilizaba en la decoración de la cerámica neolítica?",
          options = {
            {
              label = "Punzón de cobre",
              is_correct = true
            },
            {
              label = "Punzón de hueso",
              is_correct = false
            },
            {
              label = "Concha de Cardium Edule",
              is_correct = false
            }
          }
        },
        {
          id = "p7",
          image = "Q7_Tecnica_Bronce",
          text = "¿Qué técnica aparece en la Edad del Bronce?",
          options = {
            {
              label = "Grabado",
              is_correct = false
            },
            {
              label = "Fundición",
              is_correct = true
            },
            {
              label = "Talla directa",
              is_correct = false
            }
          }
        },
        {
          id = "p8",
          image = "Q8_Pottery_Bronze",
          text = "¿Qué forma cerámica no es propia de la Edad del Bronce?",
          options = {
            {
              label = "Quesera",
              is_correct = false
            },
            {
              label = "Olla",
              is_correct = false
            },
            {
              label = "Caliciforme",
              is_correct = true
            }
          }
        },
        {
          id = "p9",
          image = "Q9_248_Empuries",
          text = "¿Con qué nombre es conocido este tipo de cerámica?",
          options = {
            {
              label = "Cerámica campaniense",
              is_correct = false
            },
            {
              label = "Terra sigillata",
              is_correct = true
            },
            {
              label = "Cerámica de figuras rojas",
              is_correct = false
            }
          }
        },
        {
          id = "p10",
          image = "Q10_4060_estatera_romana",
          text = "Este objeto es una estátera romana ¿Sabes para qué se utilizaba?",
          options = {
            {
              label = "Para pescar",
              is_correct = false
            },
            {
              label = "Para la construcción de casas",
              is_correct = false
            },
            {
              label = "Para pesar objetos",
              is_correct = true
            }
          }
        }
      }
    },
    pool_2 = {
      config = {
        maximum_attempts = 3,
        total_questions = 5
      },
      questions = {
        {
          id = "q1_pool2",
          image = "QB_01",
          text = "¿Cuál es el objetivo principal de la conservación preventiva?",
          options = {
            {
              label = "Reparar los objetos que están rotos para poder exponerlos",
              is_correct = false
            },
            {
              label = "Devolver a los objetos su aspecto original, eliminando todo rastro de deterioro",
              is_correct = false
            },
            {
              label = "Crear las condiciones que ralenticen el deterioro de los objetos y prevenir daños",
              is_correct = true
            }
          }
        },
        {
          id = "q2_pool2",
          image = "QB_02",
          text = "¿Cuál de estos factores es más perjudicial para la mayoría de objetos arqueológicos?",
          options = {
            {
              label = "La gravedad",
              is_correct = false
            },
            {
              label = "La luz intensa",
              is_correct = true
            },
            {
              label = "El color de las paredes de la sala",
              is_correct = false
            }
          }
        },
        {
          id = "q3_pool2",
          image = "QB_03",
          text = "¿Por qué es importante la 'reversibilidad' de materiales y técnicas en restauración?",
          options = {
            {
              label = "Para que el proceso de restauración sea más económico",
              is_correct = false
            },
            {
              label = "Para garantizar que los tratamientos puedan deshacerse si aparecen técnicas mejores",
              is_correct = true
            },
            {
              label = "Porque así los objetos se pueden limpiar con agua sin problemas",
              is_correct = false
            }
          }
        },
        {
          id = "q4_pool2",
          image = "QB_04",
          text = "¿Por qué es importante el control de la humedad relativa en los almacenes de un museo?",
          options = {
            {
              label = "La humedad alta acelera la corrosión de metales y el crecimiento de hongos",
              is_correct = true
            },
            {
              label = "A los investigadores les resulta más incómodo y difícil trabajar con humedad",
              is_correct = false
            },
            {
              label = "Los objetos se conservan mejor en condiciones de ambiente muy seco",
              is_correct = false
            }
          }
        },
        {
          id = "q5_pool2",
          image = "QB_05",
          text = "¿Cuál es el objetivo de almacenar determinados objetos en cajas de cartón libre de ácidos?",
          options = {
            {
              label = "Mejorar su presentación visual y aumentar la capacidad de almacenamiento",
              is_correct = false
            },
            {
              label = "Abaratar los costes de almacenamiento",
              is_correct = false
            },
            {
              label = "Evitar que los materiales ácidos del embalaje dañen los objetos",
              is_correct = true
            }
          }
        }
      }
    }
  }
}
