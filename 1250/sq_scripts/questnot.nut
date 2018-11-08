// Quest Note Notifier 1.1
// 14 August 2017
// by ZylonBane
// Displays an onscreen notification when quest notes are added and completed.
//
// Localization
// By default this script prefixes new quest notes with "NOTE", and completed
// quests with "COMPLETE". To change the prefixes, add NoteAdded and NoteComplete
// to strings/misc.str. Example:
//   NoteAdded:"YO DAWG"
//   NoteComplete:"GOOD JOB"
//
// Since Dark doesn't send scripts any global notification for quest state
// changes, every possible quest note must be subscribed to individually.
// For maximum compatibility with the main campaign, main campaign mods, and
// FMs, this script attempts to discover all possible quest notes from 1 to
// 99 for decks 1 to 9 (note_1_1 to note_9_99).
//
// Dark internal quest note states:
//   0 = inactive (not visible)
//   1 = active
//   2 = complete
//   3 = "secret" complete (completed before assigned; not visible)

class zbQuestNotifier extends SqRootScript {
	// initialize script
	function OnBeginScript() {
		print("Quest Note Notifier initialized");
		local deck, num, note, state;
		local noteState = {};
		for (deck = 1; deck < 10; deck++) {
			for (num = 1; num < 100; num++) {
				note = "note_" + deck + "_" + num;
				state = Quest.Get(note);
				if (Data.GetString("notes", note) != "" && state != 2) {
					Quest.SubscribeMsg(self, note, eQuestDataType.kQuestDataCampaign);
					noteState[note] <- state;
				}
			}
		}
		SetData("noteState", tableSerialize(noteState));
	}

	// handle quest state change
	// Notifications delayed a bit so they won't get buried among the email
	// and cybermod messages that usually accompany quest state changes.
	// Quest add messages delayed a bit more so they'll always follow quest
	// completion messages when they're triggered together.
	function OnQuestChange() {
		SetOneShotTimer("QuestNotify", message().m_newValue == 1 ? 1 : 0.5, message().m_pName.tolower());
	}

	// display notification	
	function OnTimer() {
		if (message().name != "QuestNotify") {
			return;
		}
		local qName = message().data;
		local qVal = Quest.Get(qName);
		local qDesc = Data.GetString("notes", qName);
		local noteState = tableDeserialize(GetData("noteState"));
		local dataChanged = false;
		if (qVal == 1 && noteState[qName] < 1) {
			ShockGame.AddText(Data.GetString("misc", "NoteAdded", "NOVÁ POZNÁMKA") + ": " + qDesc, null, 10000);
			Sound.PlaySchema(null, "linebeep");
			noteState[qName] = 1;
			dataChanged = true;
		}
		else if (qVal == 2 && noteState[qName] != 2) {
			// suppress multiple identical completion notes (e.g. "Get to Deck 4 to meet Dr. Polito.")
			if (qDesc != GetData("noteLast")) {
				ShockGame.AddText(Data.GetString("misc", "NoteComplete", "ÚLOHA SPLNÌNA") + ": " + qDesc, null, 10000);
				Sound.PlaySchema(null, "hack_success");
				SetData("noteLast", qDesc);
			}
			noteState[qName] = 2;
			dataChanged = true;
			Quest.UnsubscribeMsg(self, qName);
		}
		if (dataChanged) {
			SetData("noteState", tableSerialize(noteState));
		}
	}

	// serialize a flat table of numeric data
	function tableSerialize(tbl) {
		local str = "";
		local key, val;
		local first = true;
		foreach (key, val in tbl) {
			str += (first ? "" : ",") + (key + ":" + val);
			first = false;
		}
		return str;
	}

	// deserialize a flat table of numeric data
	function tableDeserialize(str) {
		local tbl = {};
		local pairs = split(str, ",");
		local pair, keyval;
		foreach (pair in pairs) {
			keyval = split(pair, ":");
			tbl[keyval[0]] <- keyval[1].tointeger(10);
		}
		return tbl;
	}
}
