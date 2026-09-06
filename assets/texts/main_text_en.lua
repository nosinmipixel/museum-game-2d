-- assets/texts/main_text_en.lua
-- ═══════════════════════════════════════════════════════
-- 🧑 MAIN TEXTS — ENGLISH (reference)
-- ═══════════════════════════════════════════════════════
--
--   Names and spine_id of characters (player, npc_01..13)
--   and main game dialogues in English. Reference file
--   (EN); equivalent exists in ES.
--
-- License: GPL-3.0-only (See LICENSE in the root)
-- Defold version: 1.13
-- Last updated: 2026-08-16
-- ═══════════════════════════════════════════════════════

return {
  characters = {
    player = {
      name = "Curator",
      spine_id = "player"
    },
    npc_01 = {
      name = "Elderly man",
      spine_id = "npc_01"
    },
    npc_02 = {
      name = "University researcher",
      spine_id = "npc_01"
    },
    npc_03 = {
      name = "Hiking Club Member",
      spine_id = "npc_03"
    },
    npc_04 = {
      name = "Numismatics enthusiast",
      spine_id = "npc_04"
    },
    npc_05 = {
      name = "Primary school student",
      spine_id = "npc_05"
    },
    npc_06 = {
      name = "Local chronicler",
      spine_id = "npc_06"
    },
    npc_07 = {
      name = "Journalist",
      spine_id = "npc_07"
    },
    npc_08 = {
      name = "Private collector",
      spine_id = "npc_08"
    },
    npc_09 = {
      name = "High school student",
      spine_id = "npc_09"
    },
    npc_10 = {
      name = "Tourist",
      spine_id = "npc_10"
    },
    npc_11 = {
      name = "Restorer",
      spine_id = "npc_11"
    },
    npc_12 = {
      name = "Librarian",
      spine_id = "npc_12"
    },
    npc_13 = {
      name = "Security guard",
      spine_id = "npc_13"
    }
  },
  narrative = {
    npc_01_attempt1 = {
      dialog_1 = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "Good morning, I have come to deposit a piece that has been in my family for years.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Ummm. Wow! How interesting! \nMay I see the piece?",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "Of course! Here it is.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "By the way, could you tell me what object this is?\nYou seem very young and I am not sure you can take charge of something so valuable.",
        start_quiz = "pool_1",
        what_question = "p1",
        is_quiz = true
      },
      failure = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "Young man! You do not seem very sharp.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "I think I will keep this jewel in my family.\nA visit to the Library would not hurt you.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "Wow! I am impressed by your knowledge.\nI think I can trust you and deposit this magnificent object in your museum.",
        next = "end_success"
      }
    },
    npc_01_attempt2 = {
      dialog_1 = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "Young man, I have returned once more.\nI wanted to give you another chance to deposit this object in your museum.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "No problem.\nNow I will surely be able to identify it.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "We shall see.\nDo you already know what object it is?",
        start_quiz = "pool_1",
        what_question = "p1",
        is_quiz = true
      },
      failure = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "I see no improvement in your knowledge since last time!\nI will keep this jewel in my family.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "What a great improvement!\nI appreciate your effort!\nI think I can certainly deposit this magnificent object in your museum.",
        next = "end_success"
      }
    },
    npc_01_attempt3 = {
      dialog_1 = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "I wanted to give you one last chance to deposit here the object I own.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "It is a great responsibility.\nI must identify it.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "I hope so.\nDo you already know what object it is?",
        start_quiz = "pool_1",
        what_question = "p1",
        is_quiz = true
      },
      failure = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "You do not meet the requirements to guard this object!\nThis object will remain permanently in my family.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_01",
        anim = "talk",
        sound = "/npc_01#npc_01",
        text = "What a great improvement!\nI appreciate your effort!\nI think I can certainly deposit this legacy in your museum.",
        next = "end_success"
      }
    },
    npc_02_attempt1 = {
      dialog_1 = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Hello, I am here because I need information for a research project on Palaeolithic lithic industry.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "It is a fascinating period, the longest in human existence.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Yes. That is why I chose this speciality, although I still find it difficult to date some materials.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Could you tell me which Prehistoric period this biface belongs to?",
        start_quiz = "pool_1",
        what_question = "p2",
        is_quiz = true
      },
      failure = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Oh! I thought that you, as a curator, would help me date this piece correctly.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Although you will surely find the necessary information in the Library to document this type of object.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "It is a pleasure to have the help of true specialists like you.\nI am truly grateful.",
        next = "end_success"
      }
    },
    npc_02_attempt2 = {
      dialog_1 = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "I have returned to the museum to continue the study of materials.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "I will be happy to help you with whatever you need.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "By the way, have you found out which period the biface we saw belongs to?",
        start_quiz = "pool_1",
        what_question = "p2",
        is_quiz = true
      },
      failure = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Oh well. Dating lithic industry is not your strong suit.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Perfect. I see you have done your homework.",
        next = "end_success"
      }
    },
    npc_02_attempt3 = {
      dialog_1 = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "For my part, I continue with my research work.\nHave you made any progress in dating lithic industry?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "I continue to advance my knowledge.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Could you tell me which Prehistoric period this biface belongs to?",
        start_quiz = "pool_1",
        what_question = "p2",
        is_quiz = true
      },
      failure = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Oh dear. I will not insist on this matter with you again.\nI would not want to embarrass you in front of other colleagues.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_02",
        anim = "talk",
        sound = "/npc_02#npc_02",
        text = "Perfect. I see you have done your homework.",
        next = "end_success"
      }
    },
    npc_03_attempt1 = {
      dialog_1 = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "Good morning! I belong to the Local Hiking Club.\nWe are preparing a small exhibition on technology in Prehistory.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "I think that is a magnificent initiative.\nSpreading knowledge about Prehistory is essential.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "Exactly!\nBut we want maximum rigour and we have doubts about some technical aspects of that period.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "Could you tell us which of these materials was not used in Prehistory?",
        start_quiz = "pool_1",
        what_question = "p3",
        is_quiz = true
      },
      failure = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "Oh dear, I am afraid that answer does not match other enquiries we have made.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "Perhaps we will clear up our doubts if you consult your library's holdings.\nIn any case, I will return to see if you can shed light on this matter.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "Perfect! That confirms what we had read.\nNow our exhibition will gain much more rigour.\nThank you very much.",
        next = "end_success"
      }
    },
    npc_03_attempt2 = {
      dialog_1 = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "I have returned. I hope you have been able to find out something about the matter we discussed.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Yes, I have consulted some publications on technology in Prehistory.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "I am glad to hear that. So, have you been able to confirm which of those materials was not used in Prehistory?",
        start_quiz = "pool_1",
        what_question = "p3",
        is_quiz = true
      },
      failure = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "I am sorry to say that does not appear to be the correct answer.\nI will return to settle this matter once and for all.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "That's the way to do it! I see you have got your act together.\nThis confirmation will be of great help.",
        next = "end_success"
      }
    },
    npc_03_attempt3 = {
      dialog_1 = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "Last visit to resolve the doubt that concerns us.\nHave you learned your lesson?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "I certainly have. This time I have it clear.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "I am glad to hear that.\nSo, have you been able to confirm which of these materials was not used in Prehistory?",
        start_quiz = "pool_1",
        what_question = "p3",
        is_quiz = true
      },
      failure = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "I am sorry but I think even we have a clearer grasp of some basic concepts.\nIn any case, we will not take up any more of your time.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_03",
        anim = "talk",
        sound = "/npc_03#npc_03",
        text = "Finally! Thank goodness.\nNow we can more confidently present the content of our exhibition.",
        next = "end_success"
      }
    },
    npc_04_attempt1 = {
      dialog_1 = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "Good afternoon. I am a collector and I am especially interested in Iberian numismatics.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "That is a fascinating field.\nIberian coins are full of small details.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "Indeed.\nI am inventorying my collection and the identification of the reverses is key for correct cataloguing.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "By the way, could you tell me what the most common design is on the reverse of Iberian coins like this unit from Kelin?",
        start_quiz = "pool_1",
        what_question = "p4",
        is_quiz = true
      },
      failure = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "Hmm, I am not sure that is correct.\nI have consulted many catalogues and had reached a different conclusion.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "Surely it would do you good to review a specialised monograph on Iberian coinage.\nI will come back later.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "Exactly! A horseman with a spear.\nIt is a pleasure to speak with a professional who masters this subject.",
        next = "end_success"
      }
    },
    npc_04_attempt2 = {
      dialog_1 = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "I have returned to continue studying the pieces in your exhibition.\nHave you been able to look further into my question?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "I have reviewed some of our holdings and I believe I am in a position to answer it.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "So? What is the most typical reverse design of Iberian coins?",
        start_quiz = "pool_1",
        what_question = "p4",
        is_quiz = true
      },
      failure = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "I am afraid your answer does not match my research.\nI still trust my catalogues more.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "Bravo! Now you are correct.\nI am glad you were able to confirm it.",
        next = "end_success"
      }
    },
    npc_04_attempt3 = {
      dialog_1 = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "This is the last time I come to consult you.\nI hope you have it clear now.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "This time I am absolutely certain.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "What is the most common design on the reverse of Iberian coins?",
        start_quiz = "pool_1",
        what_question = "p4",
        is_quiz = true
      },
      failure = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "Definitely, you will need to specialise more in the field of numismatics.\nI will stick with my books.\nGood day.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_04",
        anim = "talk",
        sound = "/npc_04#npc_04",
        text = "Magnificent! A horseman.\nYou can now consider yourself an expert.\nThank you for your help.",
        next = "end_success"
      }
    },
    npc_05_attempt1 = {
      dialog_1 = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "Hello, Mr. Curator.\nWe are doing a school project on the Neolithic.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Hello! That is great, I love it when the little ones take an interest in Prehistory.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "Yes, and my teacher told us to look carefully at the stones.\nSome stones are very smooth, unlike others seem rougher.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "Do you know which stone-working technique emerges during the Neolithic and leaves it that smooth?",
        start_quiz = "pool_1",
        what_question = "p5",
        is_quiz = true
      },
      failure = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "Oh! But I think my teacher told us something else.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "Maybe if you look in those big books in the Library, you will find it.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "Yes, yes, polishing! I knew it!\nThank you very much!\nI will tell the teacher how much they know in this museum.",
        next = "end_success"
      }
    },
    npc_05_attempt2 = {
      dialog_1 = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "I have returned with my notebook.\nHave you found any more information about those very smooth stones?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Yes, I have been doing a bit of research for you.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "So? What is the name of that stone-working technique that emerged during the Neolithic?",
        start_quiz = "pool_1",
        what_question = "p5",
        is_quiz = true
      },
      failure = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "Oops, no. I think you got it wrong.\nI don't remember my teacher saying anything about that.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "You got it! Great!\nNow my teacher will definitely give me an A+.",
        next = "end_success"
      }
    },
    npc_05_attempt3 = {
      dialog_1 = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "This is the last time I can come.\nI am running out of time to do the school project.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Of course I remember!",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "Do you remember the name of that stone-working technique that emerged during the Neolithic?",
        start_quiz = "pool_1",
        what_question = "p5",
        is_quiz = true
      },
      failure = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "Wow, it seems really hard.\nDon't worry, one day I'll explain it to you myself when I learn it better.\nGoodbye!",
        next = "end_fail"
      },
      success = {
        speaker = "npc_05",
        anim = "talk",
        sound = "/npc_05#npc_05",
        text = "Great! Polishing! That's it.\nNow you really seem like a true curator.\nThank you!",
        next = "end_success"
      }
    },
    npc_06_attempt1 = {
      dialog_1 = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "Good morning. I am the official chronicler of a nearby town and I am documenting our most remote past.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "It is a pleasure.\nThe study of local history is really important as a basis for understanding broader phenomena.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "Indeed.\nAnd I would like to delve into certain aspects of the daily life of our Neolithic ancestors, 'down to their very entrails', as they say.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "Specifically, to be rigorous, could you tell me which of these elements was not used in the decoration of Neolithic pottery?",
        start_quiz = "pool_1",
        what_question = "p6",
        is_quiz = true
      },
      failure = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "Hmm, I am afraid your sources are not entirely accurate.\nThat does not agree with what I have been able to read.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "I advise you to consult your Library.\nEven in ours we have some very interesting publications on the subject.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "Exactly! I am pleased to see you are well documented.\nIt will be a pleasure to return to share knowledge.",
        next = "end_success"
      }
    },
    npc_06_attempt2 = {
      dialog_1 = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "I have returned to cross-check more data.\nHave you had time to review my question?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Yes, I have been able to consult some documents.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "Well? Have you found the anachronistic element?\nWhich of these tools was not used in the decoration of Neolithic pottery?",
        start_quiz = "pool_1",
        what_question = "p6",
        is_quiz = true
      },
      failure = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "I am sorry to say you persist in error.\nAs a chronicler, I must be inflexible on such matters.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "Correct! I see you have made good use of your time.\nTake note for future reference.",
        next = "end_success"
      }
    },
    npc_06_attempt3 = {
      dialog_1 = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "One last consultation to clear up doubts.\nI hope the answer is now definitive.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "I am confident it will be.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "Have you found the anachronistic element yet?\nWhich of these tools was not used in the decoration of Neolithic pottery?",
        start_quiz = "pool_1",
        what_question = "p6",
        is_quiz = true
      },
      failure = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "Definitely, I will inform other colleagues that this museum is not a reliable source for certain technical consultations.\nHave a good day.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_06",
        anim = "talk",
        sound = "/npc_06#npc_06",
        text = "Finally! The copper spatula, indeed.\nYou have been able to overcome my inquisitive questions.\nThank you.",
        next = "end_success"
      }
    },
    npc_07_attempt1 = {
      dialog_1 = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Good morning, I am a journalist from the magazine 'Historia Viva'.\nI am preparing a report on technological advances in antiquity.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Ah, welcome! The specialist press is always a great ally.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Thank you.\nFor the article, it is crucial to highlight technological leaps.\nThis copper axe marks a before and after, since bronze was a true revolution.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "For context, could you tell me which technique appears in the Bronze Age?",
        start_quiz = "pool_1",
        what_question = "p7",
        is_quiz = true
      },
      failure = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Mmm, that information does not match what I had.\nI will have to cross-check it with other sources to avoid publishing any errors.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Perhaps I will have to find someone who knows more about ancient metallurgy.\nI suggest you also catch up.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Smelting! Exactly.\nI can already see the headline.\nPerfect for my report.\nYou will get a special mention.",
        next = "end_success"
      }
    },
    npc_07_attempt2 = {
      dialog_1 = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "I have returned to gather more information on other topics,\nbut since I am here, I would like to know if you have found out the answer to the question from the other day.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "I think I have it clearer now.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Which technique appears in the Bronze Age?",
        start_quiz = "pool_1",
        what_question = "p7",
        is_quiz = true
      },
      failure = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Ummm, we still do not have a clear answer\nand I cannot risk publishing incorrect information.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "That's it! Smelting!\nNow I can confirm this information!",
        next = "end_success"
      }
    },
    npc_07_attempt3 = {
      dialog_1 = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "One last chance to confirm the key fact. Can you finally help me?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "This time I am sure.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Which metallurgical technique appears in the Bronze Age?",
        start_quiz = "pool_1",
        what_question = "p7",
        is_quiz = true
      },
      failure = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Definitely, I will look for another specialist.\nThank you anyway.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_07",
        anim = "talk",
        sound = "/npc_07#npc_07",
        text = "Correct! Smelting.\nI am glad you were finally able to clarify it.\nIt will be of great help.",
        next = "end_success"
      }
    },
    npc_08_attempt1 = {
      dialog_1 = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Good afternoon.\nI own a rather respectable collection of ancient pottery,\nand I sometimes come to museums like yours to... compare pieces.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "There are very interesting private collections.\nMany of their pieces can have great scientific value,\nalthough most of them have lost their archaeological context.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Well.\nI consider myself an expert.\nFor example, I have a piece that, in my judgement, is a Bronze Age pot.\nBut a rival... I mean, another collector, insists it cannot be from that period.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "To settle the matter, tell me: Which of these ceramic forms is not typical of the Bronze Age?",
        start_quiz = "pool_1",
        what_question = "p8",
        is_quiz = true
      },
      failure = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Ha! Just what I thought.\nIt seems your knowledge of ceramic forms is not very deep.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "You should visit some prestigious private collections.\nWe reach places that these public collections cannot.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Well, well! I am pleasantly surprised.\nIndeed, the calathos is much later.\nPerhaps you will be surprised to know that I also have one of those.",
        next = "end_success"
      }
    },
    npc_08_attempt2 = {
      dialog_1 = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "I have returned.\nI have been thinking about our previous conversation and wanted to give you a second chance.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "My answer will be more accurate this time, I am sure.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Let's see.\nWhich of these ceramic forms is not typical of the Bronze Age?",
        start_quiz = "pool_1",
        what_question = "p8",
        is_quiz = true
      },
      failure = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Incredible.\nI do not know if you are pulling my leg.\nThe staff at this museum are not up to the standard of my collection.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Umm, I see you have learned your lesson.\nGood for you.\nYou finally show some good judgement.",
        next = "end_success"
      }
    },
    npc_08_attempt3 = {
      dialog_1 = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Last visit.\nI hope 'third time lucky'.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "I definitely have the correct answer.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "We shall see.\nWhich of these ceramic forms is not typical of the Bronze Age?",
        start_quiz = "pool_1",
        what_question = "p8",
        is_quiz = true
      },
      failure = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "No.\nDefinitely, I do not know how they do things here.\nI prefer to trust my own judgement.\nGood day and goodbye forever.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_08",
        anim = "talk",
        sound = "/npc_08#npc_08",
        text = "Correct.\nThe calathos.\nI am glad you finally reached the right conclusion.",
        next = "end_success"
      }
    },
    npc_09_attempt1 = {
      dialog_1 = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Hello, good morning.\nSorry, we are in 1st year of secondary school and we have to do a project on Rome.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Hello! Of course, ask whatever you need.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Great, thanks.\nThis vessel really catches our attention because it has a shine and a super cool colour.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Could you tell us what this type of beautiful pottery is called?",
        start_quiz = "pool_1",
        what_question = "p9",
        is_quiz = true
      },
      failure = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Oops, I think I saw a different name in our textbook.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "We have to come back this way, so you could look it up in one of those big catalogues you have.\nOr on the internet.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Terra sigillata! That's it!\nThank you very much!\nThe teacher will definitely give us a ten.",
        next = "end_success"
      }
    },
    npc_09_attempt2 = {
      dialog_1 = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Hello, we have returned.\nDo you remember us?\nHave you looked up the name of the pottery?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Of course I remember! Yes, I have consulted catalogues of Roman pottery.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Really? What is this type of pottery called?",
        start_quiz = "pool_1",
        what_question = "p9",
        is_quiz = true
      },
      failure = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Ugh, I think that still isn't it.\nI don't know whether to ask the other history teacher at school.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Yes! I knew it!\nNow you've remembered.\nThanks for everything.",
        next = "end_success"
      }
    },
    npc_09_attempt3 = {
      dialog_1 = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Hello again.\nThis is the last time we can come by.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "This time you will have the correct name.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "What is this type of pottery called?",
        start_quiz = "pool_1",
        what_question = "p9",
        is_quiz = true
      },
      failure = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Oh well, never mind.\nWe all make mistakes.\nThanks anyway.\nGoodbye!",
        next = "end_fail"
      },
      success = {
        speaker = "npc_09",
        anim = "talk",
        sound = "/npc_09#npc_09",
        text = "Terra sigillata! Confirmed and noted!\nThank you very much for your help!",
        next = "end_success"
      }
    },
    npc_10_attempt1 = {
      dialog_1 = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "Hello! Excuse me, this museum is wonderful!\nAnd I am especially fascinated by the Roman period.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Thank you! I am glad you like it.\nDo you need any help?",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "Oh, yes! This object seems so... advanced for its time.\nI think I know what it is and I would like to mention it on my travel blog.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "This guide says it is a Roman steelyard.\nBut do you know what these objects were used for?",
        start_quiz = "pool_1",
        what_question = "p10",
        is_quiz = true
      },
      failure = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "Oh, I thought it was for something else.\nI saw a YouTube video that linked it to something different.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "Maybe you can check in your database.\nI am sure you will find the correct information.\nI will come back later.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "Yes! For weighing objects! That is what I thought.\nPerfect!\nNow I am completely sure and I can talk about it without any problems.\nThank you very much!",
        next = "end_success"
      }
    },
    npc_10_attempt2 = {
      dialog_1 = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "Hello again! I have returned to see that beautiful steelyard.\nIt is a captivating piece.\nHave you found out more about its use?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "I have been doing some research, yes.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "Great! So, what was a steelyard used for?",
        start_quiz = "pool_1",
        what_question = "p10",
        is_quiz = true
      },
      failure = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "Mmm, I am not sure that is correct.\nI have also consulted information and I have the impression you are somewhat off track.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "Oh, yes! I think we finally agree.\nIt was for weighing.\nThank you for checking and confirming it.",
        next = "end_success"
      }
    },
    npc_10_attempt3 = {
      dialog_1 = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "Last visit! I must return to my country, although I hope you have the final answer for my blog readers.",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Now I have no doubt.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "Great! So, what was a steelyard used for?",
        start_quiz = "pool_1",
        what_question = "p10",
        is_quiz = true
      },
      failure = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "I would say your information does not match mine.\nI have many doubts and I do not know if I will finally write about this object on my blog.\nThanks anyway.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_10",
        anim = "talk",
        sound = "/npc_10#npc_10",
        text = "Excellent! 'It was used to weigh objects'.\nPerfect!\nMy followers will love this detail.\nYou have been very helpful!",
        next = "end_success"
      }
    },
    npc_11_attempt1 = {
      dialog_1 = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "Oh!\nYou here!",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Hello. I would like you to analyse this object to see if it needs any intervention.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "Of course! I will gladly do it...\nBut first you will have to answer a little question.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "What is the main objective of preventive conservation?",
        start_quiz = "pool_2",
        what_question = "q1_pool2",
        is_quiz = true
      },
      failure = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "Oh dear!\nI think you are a bit lost.",
        next = "failure_end_dialog"
      },
      failure_end_dialog = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "I will make you suffer a little.\nI will let you know when you should come back.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "Correct! Preventive conservation is not about intervening directly on the object, but about protecting it by controlling its environment.",
        next = "end_success"
      }
    },
    npc_11_attempt2 = {
      dialog_1 = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "Hello again! Have you done your homework?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Yes. I have been doing some research.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "Great! So, what is the main objective of preventive conservation?",
        start_quiz = "pool_2",
        what_question = "q1_pool2",
        is_quiz = true
      },
      failure = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "Ummm, this piece will have to wait a little longer.\nI will call you again.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "Correct! Preventive conservation is not about intervening directly on the object, but about protecting it by controlling its environment.",
        next = "end_success"
      }
    },
    npc_11_attempt3 = {
      dialog_1 = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "You again! Will you be able to answer correctly this time?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Without a doubt. I definitely have the correct answer.",
        next = "dialog_quiz"
      },
      dialog_quiz = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "Perfect! Tell me, what is the main objective of preventive conservation?",
        start_quiz = "pool_2",
        what_question = "q1_pool2",
        is_quiz = true
      },
      failure = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "Oh well, I have no choice but to accept the piece for analysis.\nBut your knowledge of conservation is not going to improve.",
        next = "end_fail"
      },
      success = {
        speaker = "npc_11",
        anim = "talk",
        sound = "/npc_11#npc_11",
        text = "Correct! Preventive conservation is not about intervening directly on the object, but about protecting it by controlling its environment.",
        next = "end_success"
      }
    },
    npc_12_talk_1 = {
      dialog_1 = {
        speaker = "npc_12",
        anim = "talk",
        sound = "/npc_12#npc_12",
        text = "Good morning. Are you looking for specific information on Archaeology?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Yes, indeed. Knowledge takes up no space.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_12",
        anim = "talk",
        sound = "/npc_12#npc_12",
        text = "The size of these bookshelves seems to contradict that statement. Although I am sure you will find the answer you are looking for in them.",
        next = "end_talk"
      }
    },
    npc_12_talk_2 = {
      dialog_1 = {
        speaker = "npc_12",
        anim = "talk",
        sound = "/npc_12#npc_12",
        text = "How are you? Do you need to consult something again?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Yes. I need to broaden my knowledge.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_12",
        anim = "talk",
        sound = "/npc_12#npc_12",
        text = "Perfect. I can tell you are very motivated. Immerse yourself in reading the books.",
        next = "end_talk"
      }
    },
    npc_13_talk_1 = {
      dialog_1 = {
        speaker = "npc_13",
        anim = "talk",
        sound = "/npc_13#npc_13",
        text = "Good morning, is there any problem in the Museum?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "No. Everything is quite quiet.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_13",
        anim = "talk",
        sound = "/npc_13#npc_13",
        text = "Perfect. There are no major developments around here either.",
        next = "end_talk"
      }
    },
    npc_13_talk_2 = {
      dialog_1 = {
        speaker = "npc_13",
        anim = "talk",
        sound = "/npc_13#npc_13",
        text = "Good morning,\nHow is everything going?",
        next = "dialog_2"
      },
      dialog_2 = {
        speaker = "player",
        anim = "talk",
        sound = "/player#blablacurator",
        text = "Good, good. The day is being quiet.",
        next = "dialog_3"
      },
      dialog_3 = {
        speaker = "npc_13",
        anim = "talk",
        sound = "/npc_13#npc_13",
        text = "I am glad. May it continue like that.",
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
          text = "What object is this?",
          options = {
            {
              label = "Caliciform cup",
              is_correct = false
            },
            {
              label = "Cinerary urn",
              is_correct = false
            },
            {
              label = "Black-glazed jug",
              is_correct = true
            }
          }
        },
        {
          id = "p2",
          image = "Q2_63351_bifaz",
          text = "Which Prehistoric period does the biface belong to?",
          options = {
            {
              label = "Epipalaeolithic",
              is_correct = false
            },
            {
              label = "Neolithic",
              is_correct = false
            },
            {
              label = "Palaeolithic",
              is_correct = true
            }
          }
        },
        {
          id = "p3",
          image = "Q3_Materiales_Paleo",
          text = "Which of these materials was not used in Prehistory?",
          options = {
            {
              label = "Bone",
              is_correct = false
            },
            {
              label = "Marble",
              is_correct = true
            },
            {
              label = "Flint",
              is_correct = false
            }
          }
        },
        {
          id = "p4",
          image = "Q4_Coins_Iber",
          text = "What is the most common design on the reverse of Iberian coins?",
          options = {
            {
              label = "A horseman",
              is_correct = true
            },
            {
              label = "An ox",
              is_correct = false
            },
            {
              label = "A lion",
              is_correct = false
            }
          }
        },
        {
          id = "p5",
          image = "Q5_Tecnica_Neo",
          text = "Which stone-working technique emerges during the Neolithic?",
          options = {
            {
              label = "Direct percussion",
              is_correct = false
            },
            {
              label = "Polishing",
              is_correct = true
            },
            {
              label = "Pressure flaking",
              is_correct = false
            }
          }
        },
        {
          id = "p6",
          image = "Q6_Ceram_Neo",
          text = "Which of these tools was not used in the decoration of Neolithic pottery?",
          options = {
            {
              label = "Copper awl",
              is_correct = true
            },
            {
              label = "Bone awl",
              is_correct = false
            },
            {
              label = "Cardium edule shell",
              is_correct = false
            }
          }
        },
        {
          id = "p7",
          image = "Q7_Tecnica_Bronce",
          text = "Which technique appears in the Bronze Age?",
          options = {
            {
              label = "Engraving",
              is_correct = false
            },
            {
              label = "Smelting",
              is_correct = true
            },
            {
              label = "Direct knapping",
              is_correct = false
            }
          }
        },
        {
          id = "p8",
          image = "Q8_Pottery_Bronze",
          text = "Which ceramic form is not typical of the Bronze Age?",
          options = {
            {
              label = "Cheese mould",
              is_correct = false
            },
            {
              label = "Pot",
              is_correct = false
            },
            {
              label = "Caliciform",
              is_correct = true
            }
          }
        },
        {
          id = "p9",
          image = "Q9_248_Empuries",
          text = "What is this type of pottery called?",
          options = {
            {
              label = "Campanian ware",
              is_correct = false
            },
            {
              label = "Terra sigillata",
              is_correct = true
            },
            {
              label = "Red-figure pottery",
              is_correct = false
            }
          }
        },
        {
          id = "p10",
          image = "Q10_4060_estatera_romana",
          text = "This object is a Roman steelyard. Do you know what it was used for?",
          options = {
            {
              label = "For fishing",
              is_correct = false
            },
            {
              label = "For building houses",
              is_correct = false
            },
            {
              label = "For weighing objects",
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
          text = "What is the main objective of preventive conservation?",
          options = {
            {
              label = "To repair broken objects so they can be displayed",
              is_correct = false
            },
            {
              label = "To restore objects to their original appearance, removing all traces of deterioration",
              is_correct = false
            },
            {
              label = "To create conditions that slow down the deterioration of objects and prevent damage",
              is_correct = true
            }
          }
        },
        {
          id = "q2_pool2",
          image = "QB_02",
          text = "Which of these factors is most harmful to the majority of archaeological objects?",
          options = {
            {
              label = "Gravity",
              is_correct = false
            },
            {
              label = "Intense light",
              is_correct = true
            },
            {
              label = "The colour of the room walls",
              is_correct = false
            }
          }
        },
        {
          id = "q3_pool2",
          image = "QB_03",
          text = "Why is the 'reversibility' of materials and techniques important in restoration?",
          options = {
            {
              label = "To make the restoration process more economical",
              is_correct = false
            },
            {
              label = "To guarantee that treatments can be undone if better techniques emerge",
              is_correct = true
            },
            {
              label = "Because it allows objects to be cleaned with water without problems",
              is_correct = false
            }
          }
        },
        {
          id = "q4_pool2",
          image = "QB_04",
          text = "Why is controlling relative humidity important in museum storage areas?",
          options = {
            {
              label = "High humidity accelerates metal corrosion and the growth of fungi",
              is_correct = true
            },
            {
              label = "It makes it more uncomfortable and difficult for researchers to work with humidity",
              is_correct = false
            },
            {
              label = "Objects are better preserved in very dry environmental conditions",
              is_correct = false
            }
          }
        },
        {
          id = "q5_pool2",
          image = "QB_05",
          text = "What is the purpose of storing certain objects in acid-free cardboard boxes?",
          options = {
            {
              label = "To improve their visual presentation and increase storage capacity",
              is_correct = false
            },
            {
              label = "To reduce storage costs",
              is_correct = false
            },
            {
              label = "To prevent acidic materials from the packaging from damaging the objects",
              is_correct = true
            }
          }
        }
      }
    }
  }
}
