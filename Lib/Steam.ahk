; original by lemasato
; modified by joedf from:
; https://github.com/lemasato/Steam-Account-Switcher

Class Steam {

	Start(folder:="", exe:="", params:="") {
		defaultExe := "Steam.exe"
		defaultFolder := this.GetInstallationFolder()
		exe := exe ? exe : defaultExe
		folder := folder ? folder : defaultFolder
		params := params ? params : ""

		if (folder != defaultFolder) && !FileExist(folder "/" exe) {
			userFolder := folder, folder := defaultFolder, exe := defaultExe
			MsgBox(exe " does not exist in the specified folder!`n`"`"" userFolder "`"`"`nDetected installation folder will be used instead.`n`"`"" defaultFolder "/" defaultExe "`"`"", "", 4096)
		}

		runCmd := params ? folder "/" exe " " params : folder "/" exe, runDir := folder
		try {
			Run(runCmd, runDir)
		} catch as e {
			MsgBox("Failed to run `"`"" folder "/" exe "`"`"`n`nExtra debug infos:`nwhat: " e.what "`nfile: " e.file "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra, "", 4096)
		}
	}

	Exit(folder:="", exe:="") {
		defaultExe := "Steam.exe"
		defaultFolder := this.GetInstallationFolder()
		exe := exe ? exe : defaultExe
		folder := folder ? folder : defaultFolder

		if (folder != defaultFolder) && !FileExist(folder "/" exe) {
			userFolder := folder, folder := defaultFolder, exe := defaultExe
			MsgBox(exe " does not exist in the specified folder!`n`"`"" userFolder "`"`"`nDetected installation folder will be used instead.`n" "`"`"" defaultFolder "/" defaultExe "`"`"", "", 4096)
		}

		runCmd := folder "/" exe " -shutdown", runDir := folder
		try {
			Run(runCmd, runDir)
		} catch as e {
			MsgBox("Failed to run `"`"" folder "/" exe "`"`"" "`n`nExtra debug infos:" "`nwhat: " e.what "`nfile: " e.file "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra, "", 4096)
		}
	}

	SetAutoLoginUser(_userName) {
		try {
			RegWrite(_userName, "REG_SZ", "HKEY_CURRENT_USER\Software\Valve\Steam\", "AutoLoginUser")
		} catch OSError as e {
			MsgBox("Unable to set autologin user!", "", 4096)
		}
	}

	GetInstallationFolder() {
		folder := RegRead("HKEY_CURRENT_USER\Software\Valve\Steam\", "steamPath")

		if FileExist(folder "\Steam.exe") {
			return folder
		} else {
			MsgBox("Unable to retrieve steam installation folder!", "", 4096)
		}
	}

	GetAccountsList() {
		fileLocation := this.GetInstallationFolder() "/config/loginusers.vdf"
		fileContent := Fileread(fileLocation)

		accountsObj := map(), startPos := 1
		Loop {
			foundPos := RegExMatch(fileContent, 'i).*?"(\d+)"[\t\r\n]*?\{([."\w\d\t\r\n]*?)\}', &accSectionObj, startPos)

			if !(foundPos) {
				Break
			}

			thisAccObj := map("SteamID", accSectionObj.1)
			Loop Parse, accSectionObj.2, "`n", "`r"
			{
				if RegExMatch(A_LoopField, '.*"(.*?)".*"(.*?)"', &lineContentObj) {
					thisAccObj[lineContentObj.1] := lineContentObj.2
				}
			}
			thisAccName := thisAccObj["AccountName"]
			accountsObj[thisAccName] := map()
			for key, value in thisAccObj
				accountsObj[thisAccName][key] := value

			startPos := foundPos + StrLen(accSectionObj.0)
		}

		return accountsObj
	}

	SetAccountSettings(_accName, _settings) {
		fileLocation := this.GetInstallationFolder() "/config/loginusers.vdf"
		fileContent := Fileread(fileLocation)
		newfileContent := fileContent

		accList := this.GetAccountsList()

		startPos := 1
		foundAcc := False
		Loop {
			foundPos := RegExMatch(fileContent, 'i)"\d+"[\t\r\n]*?\{([."\w\d\t\r\n]*?)\}', &accSection, startPos)
			if !(foundPos)
				Break

			if RegExMatch(accSection.1, 'i).*"AccountName".*"' _accName '"') {

				for setting, value in _settings {
					hasSetting := accList[_accName][setting] != "" ? True : False
					if (hasSetting)
						newFileContent := RegExReplace(newFileContent, 'i)"' setting '"(.*?)"(.*?)"', '"' setting '"$1"' value '"', &rcount, 1, startPos)
					else
						newFileContent := RegExReplace(newFileContent, 'i)"Timestamp"(.*?)"(\d+)"', '"Timestamp"$1"$2"`n$1"' setting '"$1"' value '"', , 1, startPos)
				}
				foundAcc := True
			}

			startPos := foundPos + StrLen(accSection.0)
		}

		if (foundAcc) {
			fileObj := FileOpen(fileLocation, "r")
			fileEnc := fileObj.Encoding
			fileObj.Close()
			fileObj := FileOpen(fileLocation, "w", fileEnc)
			fileObj.Write(newFileContent)
			fileObj.Close()
		}
	}

	SetActiveUser(_userName, _settings:="") {
		if (!IsObject(_settings))
			_settings := map("WantsOfflineMode", 0, "SkipOfflineModeWarning", 0)
		this.SetAutoLoginUser(_userName)
		this.SetAccountSettings(_userName, _settings)
	}
}
