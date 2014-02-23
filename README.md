Easy Scoreboard
==============

because you can't lua
--------------

**Things you can config-**

- EZS.Enabled = true/false (enabled/disabled)

- EZS.Colors["rank"] = Color(r,g,b) -- use "rainbow" for rainbow name

- EZS.Ranks["rank"] = "NameToDisplay"
- EZS.RankPos = number PositionOnScoreboard
- EZS.RankOffset = number OffsetPosition (negative is left)
- EZS.CreateRankLabel = { enabled = true/false, text = "TitleText" } (The label to show at the top of the scoreboard)

- EZS.UseNameColors = true/false (Color name with EZS.Colors for that rank?)
- EZS.RainbowFrequency = number Frequency (the speed to cycle through rainbow)

- EZS.DrawBackground = true/false (Draw a black bar behind the rank?)
- EZS.BackgroundSize = number SizeOfBackground (default 50)

- EZS.MoveTag = { enabled = true/false, amount = number } (Move tags (missing,suspect,etc) over to the left?)