;@Ahk2Exe-SetMainIcon res/icon.ico
;@Ahk2Exe-SetCopyright joedf (2021)
;@Ahk2Exe-SetDescription Simplest AHK based Steam account switcher.
#Requires AutoHotkey >=2.0-
#Include <Steam>

myGui := Gui()
myGui.OnEvent("Close", GuiClose)
LV := myGui.Add("ListView", "vLVA", ["Double-Click user name to switch account"])
LV.OnEvent("DoubleClick", SwitchAccount)
myGui.Title := "Steam Switcher"
myGui.Show()
st := Steam()
ListAccounts()
return

GuiClose(*)
{
	ExitApp()
}

ListAccounts()
{
	acc := st.GetAccountsList()
	for k, v in acc
		LV.Add("", k)
	return
}

SwitchAccount(LV, RowNumber)
{
	UserName := LV.GetText(RowNumber)
	if StrLen(UserName) > 3
	{
		LV.Enabled := false
		st.SetActiveUser(UserName)
		RestartSteam()

		ExitApp()
	}
}

RestartSteam() {
	if (pid := ProcessExist("steam.exe")) {
		LV.Add("", "Restarting Steam, please wait ...")
		st.Exit()
		waitPid := ProcessWaitClose(pid, 5)
		Sleep(3000)
	} else {
		LV.Add("", "Starting Steam, please wait ...")
	}
	st.Start()
}
