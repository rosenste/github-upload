'----------------------------------------------------------------------
'
' Copyright (c) Microsoft Corporation. All rights reserved.
'
' Abstract:
' prnjobs.vbs - job control script for WMI on Windows 
'     used to pause, resume, cancel and list jobs
'
' Usage:
' prnjobs [-zmxl?] [-s server] [-p printer] [-j jobid] [-u user name] [-w password]
'
' Examples:
' prnjobs -z -j jobid -p printer
' prnjobs -l -p printer
'
'----------------------------------------------------------------------

option explicit

'
' Debugging trace flags, to enable debug output trace message
' change gDebugFlag to true.
'
const kDebugTrace = 1
const kDebugError = 2
dim   gDebugFlag

gDebugFlag = false

'
' Operation action values.
'
const kActionUnknown    = 0
const kActionPause      = 1
const kActionResume     = 2
const kActionCancel     = 3
const kActionList       = 4

const kErrorSuccess     = 0
const KErrorFailure     = 1

const kNameSpace        = "root\cimv2"

'
' Job status constants
'
const kJobPaused        = 1
const kJobError         = 2
const kJobDeleting      = 4
const kJobSpooling      = 8
const kJobPrinting      = 16
const kJobOffline       = 32
const kJobPaperOut      = 64
const kJobPrinted       = 128
const kJobDeleted       = 256
const kJobBlockedDevq   = 512
const kJobUserInt       = 1024
const kJobRestarted     = 2048
const kJobComplete      = 4096

'
' Generic strings
'
const L_Empty_Text                 = ""
const L_Space_Text                 = " "
const L_Error_Text                 = "Error"
const L_Success_Text               = "Success"
const L_Failed_Text                = "Failed"
const L_Hex_Text                   = "0x"
const L_Printer_Text               = "Printer"
const L_Operation_Text             = "Operation"
const L_Provider_Text              = "Provider"
const L_Description_Text           = "Description"
const L_Debug_Text                 = "Debug:"

'
' General usage messages
'
const L_Help_Help_General01_Text   = "Usage: prnjobs [-zmxl?] [-s server][-p printer][-j jobid][-u user name][-w password]"
const L_Help_Help_General02_Text   = "Arguments:"
const L_Help_Help_General03_Text   = "-j     - job id"
const L_Help_Help_General04_Text   = "-l     - list all jobs"
const L_Help_Help_General05_Text   = "-m     - resume the job"
const L_Help_Help_General06_Text   = "-p     - printer name"
const L_Help_Help_General07_Text   = "-s     - server name"
const L_Help_Help_General08_Text   = "-u     - user name"
const L_Help_Help_General09_Text   = "-w     - password"
const L_Help_Help_General10_Text   = "-x     - cancel the job"
const L_Help_Help_General11_Text   = "-z     - pause the job"
const L_Help_Help_General12_Text   = "-?     - display command usage"
const L_Help_Help_General13_Text   = "Examples:"
const L_Help_Help_General14_Text   = "prnjobs -z -p printer -j jobid"
const L_Help_Help_General15_Text   = "prnjobs -l -p printer"
const L_Help_Help_General16_Text   = "prnjobs -l"

'
' Messages to be displayed if the scripting host is not cscript
'
const L_Help_Help_Host01_Text      = "This script should be executed from the Command Prompt using CScript.exe."
const L_Help_Help_Host02_Text      = "For example: CScript script.vbs arguments"
const L_Help_Help_Host03_Text      = ""
const L_Help_Help_Host04_Text      = "To set CScript as the default application to run .VBS files run the following:"
const L_Help_Help_Host05_Text      = "     CScript //H:CScript //S"
const L_Help_Help_Host06_Text      = "You can then run ""script.vbs arguments"" without preceding the script with CScript."

'
' General error messages
'
const L_Text_Error_General01_Text  = "The scripting host could not be determined."
const L_Text_Error_General02_Text  = "Unable to parse command line."
const L_Text_Error_General03_Text  = "Win32 error code"

'
' Miscellaneous messages
'
const L_Text_Msg_General01_Text    = "Unable to enumerate print jobs"
const L_Text_Msg_General02_Text    = "Number of print jobs enumerated"
const L_Text_Msg_General03_Text    = "Unable to set print job"
const L_Text_Msg_General04_Text    = "Unable to get SWbemLocator object"
const L_Text_Msg_General05_Text    = "Unable to connect to WMI service"


'
' Print job properties
'
const L_Text_Msg_Job01_Text        = "Job id"
const L_Text_Msg_Job02_Text        = "Printer"
const L_Text_Msg_Job03_Text        = "Document"
const L_Text_Msg_Job04_Text        = "Data type"
const L_Text_Msg_Job05_Text        = "Driver name"
const L_Text_Msg_Job06_Text        = "Description"
const L_Text_Msg_Job07_Text        = "Elapsed time"
const L_Text_Msg_Job08_Text        = "Machine name"
const L_Text_Msg_Job09_Text        = "Notify"
const L_Text_Msg_Job10_Text        = "Owner"
const L_Text_Msg_Job11_Text        = "Pages printed"
const L_Text_Msg_Job12_Text        = "Parameters"
const L_Text_Msg_Job13_Text        = "Size"
const L_Text_Msg_Job14_Text        = "Start time"
const L_Text_Msg_Job15_Text        = "Until time"
const L_Text_Msg_Job16_Text        = "Status"
const L_Text_Msg_Job17_Text        = "Time submitted"
const L_Text_Msg_Job18_Text        = "Total pages"
const L_Text_Msg_Job19_Text        = "SizeHigh"
const L_Text_Msg_Job20_Text        = "PaperSize"
const L_Text_Msg_Job21_Text        = "PaperWidth"
const L_Text_Msg_Job22_Text        = "PaperLength"
const L_Text_Msg_Job23_Text        = "Color"

'
' Job status strings
'
const L_Text_Msg_Status01_Text     = "The driver cannot print the job"
const L_Text_Msg_Status02_Text     = "Sent to the printer"
const L_Text_Msg_Status03_Text     = "Job has been deleted"
const L_Text_Msg_Status04_Text     = "Job is being deleted"
const L_Text_Msg_Status05_Text     = "An error is associated with the job"
const L_Text_Msg_Status06_Text     = "Printer is offline"
const L_Text_Msg_Status07_Text     = "Printer is out of paper"
const L_Text_Msg_Status08_Text     = "Job is paused"
const L_Text_Msg_Status09_Text     = "Job has printed"
const L_Text_Msg_Status10_Text     = "Job is printing"
const L_Text_Msg_Status11_Text     = "Job has been restarted"
const L_Text_Msg_Status12_Text     = "Job is spooling"
const L_Text_Msg_Status13_Text     = "Printer has an error that requires user intervention"

'
' Action strings
'
const L_Text_Action_General01_Text = "Pause"
const L_Text_Action_General02_Text = "Resume"
const L_Text_Action_General03_Text = "Cancel"

'
' Debug messages
'
const L_Text_Dbg_Msg01_Text        = "In function ListJobs"
const L_Text_Dbg_Msg02_Text        = "In function ExecJob"
const L_Text_Dbg_Msg03_Text        = "In function ParseCommandLine"

main

'
' Main execution starts here
'
sub main

    dim iAction
    dim iRetval
    dim strServer
    dim strPrinter
    dim strJob
    dim strUser
    dim strPassword

    '
    ' Abort if the host is not cscript
    '
    if not IsHostCscript() then

        call wscript.echo(L_Help_Help_Host01_Text & vbCRLF & L_Help_Help_Host02_Text & vbCRLF & _
                          L_Help_Help_Host03_Text & vbCRLF & L_Help_Help_Host04_Text & vbCRLF & _
                          L_Help_Help_Host05_Text & vbCRLF & L_Help_Help_Host06_Text & vbCRLF)

        wscript.quit

    end if

    iRetval = ParseCommandLine(iAction, strServer, strPrinter, strJob, strUser, strPassword)

    if iRetval = kErrorSuccess then

        select case iAction

            case kActionPause
                 iRetval = ExecJob(strServer, strJob, strPrinter, strUser, strPassword, L_Text_Action_General01_Text)

            case kActionResume
                 iRetval = ExecJob(strServer, strJob, strPrinter, strUser, strPassword, L_Text_Action_General02_Text)

            case kActionCancel
                 iRetval = ExecJob(strServer, strJob, strPrinter, strUser, strPassword, L_Text_Action_General03_Text)

            case kActionList
                 iRetval = ListJobs(strServer, strPrinter, strUser, strPassword)

            case else
                 Usage(true)
                 exit sub

        end select

    end if

end sub

'
' Enumerate all print jobs on a printer
'
function ListJobs(strServer, strPrinter, strUser, strPassword)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg01_Text

    dim Jobs
    dim oJob
    dim oService
    dim iRetval
    dim strTemp
    dim iTotal

    if WmiConnect(strServer, kNameSpace, strUser, strPassword, oService) then

        set Jobs = oService.InstancesOf("Win32_PrintJob")

    else

        ListJobs = kErrorFailure

        exit function

    end if

    if Err.Number <> kErrorSuccess then

        wscript.echo L_Text_Msg_General01_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

        ListJobs = kErrorFailure

        exit function

    end if

    iTotal = 0

    for each oJob in Jobs

        '
        ' oJob.Name has the form "printer name, job id". We are isolating the printer name
        '
        strTemp = Mid(oJob.Name, 1, InStr(1, oJob.Name, ",", 1)-1 )

        '
        ' If no printer was specified, then enumerate all jobs
        '
        if strPrinter = null or strPrinter = "" or LCase(strTemp) = LCase(strPrinter) then

            iTotal = iTotal + 1

            wscript.echo L_Empty_Text
            wscript.echo L_Text_Msg_Job01_Text & L_Space_Text & oJob.JobId
            wscript.echo L_Text_Msg_Job02_Text & L_Space_Text & strTemp
            wscript.echo L_Text_Msg_Job03_Text & L_Space_Text & oJob.Document
            wscript.echo L_Text_Msg_Job04_Text & L_Space_Text & oJob.DataType
            wscript.echo L_Text_Msg_Job05_Text & L_Space_Text & oJob.DriverName
            wscript.echo L_Text_Msg_Job06_Text & L_Space_Text & oJob.Description
            wscript.echo L_Text_Msg_Job07_Text & L_Space_Text & Mid(CStr(oJob.ElapsedTime), 9, 2) & ":" _
                                                              & Mid(CStr(oJob.ElapsedTime), 11, 2) & ":" _
                                                              & Mid(CStr(oJob.ElapsedTime), 13, 2)
            wscript.echo L_Text_Msg_Job08_Text & L_Space_Text & oJob.HostPrintQueue
            wscript.echo L_Text_Msg_Job09_Text & L_Space_Text & oJob.Notify
            wscript.echo L_Text_Msg_Job10_Text & L_Space_Text & oJob.Owner
            wscript.echo L_Text_Msg_Job11_Text & L_Space_Text & oJob.PagesPrinted
            wscript.echo L_Text_Msg_Job12_Text & L_Space_Text & oJob.Parameters
            wscript.echo L_Text_Msg_Job13_Text & L_Space_Text & oJob.Size
            wscript.echo L_Text_Msg_Job19_Text & L_Space_Text & oJob.SizeHigh
            wscript.echo L_Text_Msg_Job20_Text & L_Space_Text & oJob.PaperSize
            wscript.echo L_Text_Msg_Job21_Text & L_Space_Text & oJob.PaperWidth
            wscript.echo L_Text_Msg_Job22_Text & L_Space_Text & oJob.PaperLength
            wscript.echo L_Text_Msg_Job23_Text & L_Space_Text & oJob.Color

            if CStr(oJob.StartTime) <> "********000000.000000+000" and _
               CStr(oJob.UntilTime) <> "********000000.000000+000" then

                wscript.echo L_Text_Msg_Job14_Text & L_Space_Text & Mid(Mid(CStr(oJob.StartTime), 9, 4), 1, 2) & "h" _
                                                                  & Mid(Mid(CStr(oJob.StartTime), 9, 4), 3, 2)
                wscript.echo L_Text_Msg_Job15_Text & L_Space_Text & Mid(Mid(CStr(oJob.UntilTime), 9, 4), 1, 2) & "h" _
                                                                  & Mid(Mid(CStr(oJob.UntilTime), 9, 4), 3, 2)
            end if

            wscript.echo L_Text_Msg_Job16_Text & L_Space_Text & JobStatusToString(oJob.StatusMask)
            wscript.echo L_Text_Msg_Job17_Text & L_Space_Text & Mid(CStr(oJob.TimeSubmitted), 5, 2) & "/" _
                                                              & Mid(CStr(oJob.TimeSubmitted), 7, 2) & "/" _
                                                              & Mid(CStr(oJob.TimeSubmitted), 1, 4) & " " _
                                                              & Mid(CStr(oJob.TimeSubmitted), 9, 2) & ":" _
                                                              & Mid(CStr(oJob.TimeSubmitted), 11, 2) & ":" _
                                                              & Mid(CStr(oJob.TimeSubmitted), 13, 2)
            wscript.echo L_Text_Msg_Job18_Text & L_Space_Text & oJob.TotalPages

            Err.Clear

        end if

    next

    wscript.echo L_Empty_Text
    wscript.echo L_Text_Msg_General02_Text & L_Space_Text & iTotal

    ListJobs = kErrorSuccess

end function

'
' Convert the job status from bit mask to string
'
function JobStatusToString(Status)

    on error resume next

    dim strString

    strString = L_Empty_Text

    if (Status and kJobPaused)      = kJobPaused      then strString = strString & L_Text_Msg_Status08_Text & L_Space_Text end if
    if (Status and kJobError)       = kJobError       then strString = strString & L_Text_Msg_Status05_Text & L_Space_Text end if
    if (Status and kJobDeleting)    = kJobDeleting    then strString = strString & L_Text_Msg_Status04_Text & L_Space_Text end if
    if (Status and kJobSpooling)    = kJobSpooling    then strString = strString & L_Text_Msg_Status12_Text & L_Space_Text end if
    if (Status and kJobPrinting)    = kJobPrinting    then strString = strString & L_Text_Msg_Status10_Text & L_Space_Text end if
    if (Status and kJobOffline)     = kJobOffline     then strString = strString & L_Text_Msg_Status06_Text & L_Space_Text end if
    if (Status and kJobPaperOut)    = kJobPaperOut    then strString = strString & L_Text_Msg_Status07_Text & L_Space_Text end if
    if (Status and kJobPrinted)     = kJobPrinted     then strString = strString & L_Text_Msg_Status09_Text & L_Space_Text end if
    if (Status and kJobDeleted)     = kJobDeleted     then strString = strString & L_Text_Msg_Status03_Text & L_Space_Text end if
    if (Status and kJobBlockedDevq) = kJobBlockedDevq then strString = strString & L_Text_Msg_Status01_Text & L_Space_Text end if
    if (Status and kJobUserInt)     = kJobUserInt     then strString = strString & L_Text_Msg_Status13_Text & L_Space_Text end if
    if (Status and kJobRestarted)   = kJobRestarted   then strString = strString & L_Text_Msg_Status11_Text & L_Space_Text end if
    if (Status and kJobComplete)    = kJobComplete    then strString = strString & L_Text_Msg_Status02_Text & L_Space_Text end if

    JobStatusToString = strString

end function

'
' Pause/Resume/Cancel jobs
'
function ExecJob(strServer, strJob, strPrinter, strUser, strPassword, strCommand)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg02_Text

    dim oJob
    dim oService
    dim iRetval
    dim uResult
    dim strName

    '
    ' Build up the key. The key for print jobs is "printer-name, job-id"
    '
    strName = strPrinter & ", " & strJob

    iRetval = kErrorFailure

    if WmiConnect(strServer, kNameSpace, strUser, strPassword, oService) then

        set oJob = oService.Get("Win32_PrintJob.Name='" & strName & "'")

    else

        ExecJob = kErrorFailure

        exit function

    end if

    '
    ' Check if getting job instance succeeded
    '
    if Err.Number = kErrorSuccess then

        uResult = kErrorSuccess

        select case strCommand

            case L_Text_Action_General01_Text
                 uResult = oJob.Pause()

            case L_Text_Action_General02_Text
                 uResult = oJob.Resume()

            case L_Text_Action_General03_Text
                 oJob.Delete_()

             case else
                 Usage(true)

        end select

        if Err.Number = kErrorSuccess then

            if uResult = kErrorSuccess then

                wscript.echo L_Success_Text & L_Space_Text & strCommand & L_Space_Text _
                             & L_Text_Msg_Job01_Text & L_Space_Text & strJob _
                             & L_Space_Text & L_Printer_Text & L_Space_Text & strPrinter

                iRetval = kErrorSuccess

            else

                wscript.echo L_Failed_Text & L_Space_Text & strCommand & L_Space_Text _
                             & L_Text_Error_General03_Text & L_Space_Text & uResult

            end if

        else

            wscript.echo L_Text_Msg_General03_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                         & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

            '
            ' Try getting extended error information
            '
            call LastError()

        end if

   else

        wscript.echo L_Text_Msg_General03_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

        '
        ' Try getting extended error information
        '
        call LastError()

    end if

    ExecJob = iRetval

end function

'
' Debug display helper function
'
sub DebugPrint(uFlags, strString)

    if gDebugFlag = true then

        if uFlags = kDebugTrace then

            wscript.echo L_Debug_Text & L_Space_Text & strString

        end if

        if uFlags = kDebugError then

            if Err <> 0 then

                wscript.echo L_Debug_Text & L_Space_Text & strString & L_Space_Text _
                             & L_Error_Text & L_Space_Text & L_Hex_Text & hex(Err.Number) _
                             & L_Space_Text & Err.Description

            end if

        end if

    end if

end sub

'
' Parse the command line into its components
'
function ParseCommandLine(iAction, strServer, strPrinter, strJob, strUser, strPassword)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg03_Text

    dim oArgs
    dim iIndex

    iAction = kActionUnknown
    iIndex = 0

    set oArgs = wscript.Arguments

    while iIndex < oArgs.Count

        select case oArgs(iIndex)

            case "-z"
                iAction = kActionPause

            case "-m"
                iAction = kActionResume

            case "-x"
                iAction = kActionCancel

            case "-l"
                iAction = kActionList

            case "-p"
                iIndex = iIndex + 1
                strPrinter = oArgs(iIndex)

            case "-s"
                iIndex = iIndex + 1
                strServer = RemoveBackslashes(oArgs(iIndex))

            case "-j"
                iIndex = iIndex + 1
                strJob = oArgs(iIndex)

            case "-u"
                iIndex = iIndex + 1
                strUser = oArgs(iIndex)

            case "-w"
                iIndex = iIndex + 1
                strPassword = oArgs(iIndex)

            case "-?"
                Usage(true)
                exit function

            case else
                Usage(true)
                exit function

        end select

        iIndex = iIndex + 1

    wend

    if Err.Number = kErrorSuccess then

        ParseCommandLine = kErrorSuccess

    else

        wscript.echo L_Text_Error_General02_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_text & Err.Description

        ParseCommandLine = kErrorFailure

    end if

end function

'
' Display command usage.
'
sub Usage(bExit)

    wscript.echo L_Help_Help_General01_Text
    wscript.echo L_Empty_Text
    wscript.echo L_Help_Help_General02_Text
    wscript.echo L_Help_Help_General03_Text
    wscript.echo L_Help_Help_General04_Text
    wscript.echo L_Help_Help_General05_Text
    wscript.echo L_Help_Help_General06_Text
    wscript.echo L_Help_Help_General07_Text
    wscript.echo L_Help_Help_General08_Text
    wscript.echo L_Help_Help_General09_Text
    wscript.echo L_Help_Help_General10_Text
    wscript.echo L_Help_Help_General11_Text
    wscript.echo L_Help_Help_General12_Text
    wscript.echo L_Empty_Text
    wscript.echo L_Help_Help_General13_Text
    wscript.echo L_Help_Help_General14_Text
    wscript.echo L_Help_Help_General15_Text
    wscript.echo L_Help_Help_General16_Text

    if bExit then

        wscript.quit(1)

    end if

end sub

'
' Determines which program is being used to run this script.
' Returns true if the script host is cscript.exe
'
function IsHostCscript()

    on error resume next

    dim strFullName
    dim strCommand
    dim i, j
    dim bReturn

    bReturn = false

    strFullName = WScript.FullName

    i = InStr(1, strFullName, ".exe", 1)

    if i <> 0 then

        j = InStrRev(strFullName, "\", i, 1)

        if j <> 0 then

            strCommand = Mid(strFullName, j+1, i-j-1)

            if LCase(strCommand) = "cscript" then

                bReturn = true

            end if

        end if

    end if

    if Err <> 0 then

        wscript.echo L_Text_Error_General01_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

    end if

    IsHostCscript = bReturn

end function

'
' Retrieves extended information about the last error that occurred
' during a WBEM operation. The methods that set an SWbemLastError
' object are GetObject, PutInstance, DeleteInstance
'
sub LastError()

    on error resume next

    dim oError

    set oError = CreateObject("WbemScripting.SWbemLastError")

    if Err = kErrorSuccess then

        wscript.echo L_Operation_Text            & L_Space_Text & oError.Operation
        wscript.echo L_Provider_Text             & L_Space_Text & oError.ProviderName
        wscript.echo L_Description_Text          & L_Space_Text & oError.Description
        wscript.echo L_Text_Error_General03_Text & L_Space_Text & oError.StatusCode

    end if

end sub

'
' Connects to the WMI service on a server. oService is returned as a service
' object (SWbemServices)
'
function WmiConnect(strServer, strNameSpace, strUser, strPassword, oService)

    on error resume next

    dim oLocator
    dim bResult

    oService = null

    bResult  = false

    set oLocator = CreateObject("WbemScripting.SWbemLocator")

    if Err = kErrorSuccess then

        set oService = oLocator.ConnectServer(strServer, strNameSpace, strUser, strPassword)

        if Err = kErrorSuccess then

            bResult = true

            oService.Security_.impersonationlevel = 3

            '
            ' Required to perform administrative tasks on the spooler service
            '
            oService.Security_.Privileges.AddAsString "SeLoadDriverPrivilege"

            Err.Clear

        else

            wscript.echo L_Text_Msg_General05_Text & L_Space_Text & L_Error_Text _
                         & L_Space_Text & L_Hex_Text & hex(Err.Number) & L_Space_Text _
                         & Err.Description

        end if

    else

        wscript.echo L_Text_Msg_General04_Text & L_Space_Text & L_Error_Text _
                     & L_Space_Text & L_Hex_Text & hex(Err.Number) & L_Space_Text _
                     & Err.Description

    end if

    WmiConnect = bResult

end function

'
' Remove leading "\\" from server name
'
function RemoveBackslashes(strServer)

    dim strRet

    strRet = strServer

    if Left(strServer, 2) = "\\" and Len(strServer) > 2 then

        strRet = Mid(strServer, 3)

    end if

    RemoveBackslashes = strRet

end function

'' SIG '' Begin signature block
'' SIG '' MIIiFQYJKoZIhvcNAQcCoIIiBjCCIgICAQExDzANBglg
'' SIG '' hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
'' SIG '' BgEEAYI3AgEeMCQCAQEEEE7wKRaZJ7VNj+Ws4Q8X66sC
'' SIG '' AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' KB4xm2kUt3OhuuVqyIMeDTFOGLaCpXJYI64NQQxGXLqg
'' SIG '' ggrlMIIFBjCCA+6gAwIBAgITMwAAAjJB+1mZbcxN/wAA
'' SIG '' AAACMjANBgkqhkiG9w0BAQsFADCBhDELMAkGA1UEBhMC
'' SIG '' VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
'' SIG '' B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
'' SIG '' b3JhdGlvbjEuMCwGA1UEAxMlTWljcm9zb2Z0IFdpbmRv
'' SIG '' d3MgUHJvZHVjdGlvbiBQQ0EgMjAxMTAeFw0xOTA1MDIy
'' SIG '' MTI0MzZaFw0yMDA1MDIyMTI0MzZaMHAxCzAJBgNVBAYT
'' SIG '' AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
'' SIG '' EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
'' SIG '' cG9yYXRpb24xGjAYBgNVBAMTEU1pY3Jvc29mdCBXaW5k
'' SIG '' b3dzMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
'' SIG '' AQEAkmMTW3blBvpQKCDDXK/qDRFmtkH12HU/EORg4uZT
'' SIG '' OZNkyZ6OACn2S/VHlqD6yqKIAswQrkk7hfdXAJoOr/ET
'' SIG '' XX4LZdPYwL8I5i6bfWJnayMhRumX4N39LejeSYTgT9Xy
'' SIG '' fHWdIAVuUqVhnGqXieg3sAJHNwN078a+14PVJOkfXI/1
'' SIG '' O6GnrB8HLqD5ecfRdhUP2GQABAL8XENIeNROTUQ2/Z26
'' SIG '' W/Hs8D5s2srKtBKSQSxUthQ0FMWz48QeqtCkF1RgDDc7
'' SIG '' mp1bmEUclc3a0sCT8ZadE1jScCm6VJrEvjSkMFAG59M6
'' SIG '' Sce1eghyBiCHH2oI38nWk45IQTFvN3eqa7II9QIDAQAB
'' SIG '' o4IBgjCCAX4wHwYDVR0lBBgwFgYKKwYBBAGCNwoDBgYI
'' SIG '' KwYBBQUHAwMwHQYDVR0OBBYEFK2ry00W9dboM/rs2r4Z
'' SIG '' pOfRxbtaMFQGA1UdEQRNMEukSTBHMS0wKwYDVQQLEyRN
'' SIG '' aWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0
'' SIG '' ZWQxFjAUBgNVBAUTDTIyOTg3OSs0NTQxMTIwHwYDVR0j
'' SIG '' BBgwFoAUqSkCOY4WxJd4zZD5nk+a4XxVr1MwVAYDVR0f
'' SIG '' BE0wSzBJoEegRYZDaHR0cDovL3d3dy5taWNyb3NvZnQu
'' SIG '' Y29tL3BraW9wcy9jcmwvTWljV2luUHJvUENBMjAxMV8y
'' SIG '' MDExLTEwLTE5LmNybDBhBggrBgEFBQcBAQRVMFMwUQYI
'' SIG '' KwYBBQUHMAKGRWh0dHA6Ly93d3cubWljcm9zb2Z0LmNv
'' SIG '' bS9wa2lvcHMvY2VydHMvTWljV2luUHJvUENBMjAxMV8y
'' SIG '' MDExLTEwLTE5LmNydDAMBgNVHRMBAf8EAjAAMA0GCSqG
'' SIG '' SIb3DQEBCwUAA4IBAQCuhuOC7ibjAyowaec6WAd81gq7
'' SIG '' DgJwmNjyVHJvVwsA03nCQGMYAIt9pw0oC+QUezSFNyCQ
'' SIG '' MV0V1pCPUhztpMcJ3r/QSYVWq4lAcqdrOB7fOcVe/g96
'' SIG '' J9c+g5As9/0CgI/e0L3iL8Kh9tzJib3saAO/MNOuRSxb
'' SIG '' Er6RzwOrvF54TESfistFmzacf9bd3PnRyUbwJEdW3o8D
'' SIG '' rd6+Az898wZeHiw/Miv9HCHnmFKTI3/pCK9MK3hgchHZ
'' SIG '' +DlMANStuIOMzV3g5Md33fVm6gmOUg+BK6tiGOXGZkTb
'' SIG '' 74donBOZtjAnBRK7Gq2HgWZGKzvvIkYJ7Vdx0JdaZbxE
'' SIG '' rg9uIXeTMIIF1zCCA7+gAwIBAgIKYQd2VgAAAAAACDAN
'' SIG '' BgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzAR
'' SIG '' BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
'' SIG '' bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
'' SIG '' bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
'' SIG '' aWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMTExMDE5MTg0
'' SIG '' MTQyWhcNMjYxMDE5MTg1MTQyWjCBhDELMAkGA1UEBhMC
'' SIG '' VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
'' SIG '' B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
'' SIG '' b3JhdGlvbjEuMCwGA1UEAxMlTWljcm9zb2Z0IFdpbmRv
'' SIG '' d3MgUHJvZHVjdGlvbiBQQ0EgMjAxMTCCASIwDQYJKoZI
'' SIG '' hvcNAQEBBQADggEPADCCAQoCggEBAN0Mu6LkLgnj58X3
'' SIG '' lmm8ACG9aTMz760Ey1SA7gaDu8UghNn30ovzOLCrpK0t
'' SIG '' fGJ5Bf/jSj8ENSBw48Tna+CcwDZ16Yox3Y1w5dw3tXRG
'' SIG '' lihbh2AjLL/cR6Vn91EnnnLrB6bJuR47UzV85dPsJ7mH
'' SIG '' HP65ySMJb6hGkcFuljxB08ujP10Cak3saR8lKFw2//1D
'' SIG '' FQqU4Bm0z9/CEuLCWyfuJ3gwi1sqCWsiiVNgFizAaB1T
'' SIG '' uuxJ851hjIVoCXNEXX2iVCvdefcVzzVdbBwrXM68nCOL
'' SIG '' b261Jtk2E8NP1ieuuTI7QZIs4cfNd+iqVE73XAsEh2W0
'' SIG '' QxiosuBtGXfsWiT6SAMCAwEAAaOCAUMwggE/MBAGCSsG
'' SIG '' AQQBgjcVAQQDAgEAMB0GA1UdDgQWBBSpKQI5jhbEl3jN
'' SIG '' kPmeT5rhfFWvUzAZBgkrBgEEAYI3FAIEDB4KAFMAdQBi
'' SIG '' AEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB
'' SIG '' /zAfBgNVHSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvXzpoY
'' SIG '' xDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1p
'' SIG '' Y3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNS
'' SIG '' b29DZXJBdXRfMjAxMC0wNi0yMy5jcmwwWgYIKwYBBQUH
'' SIG '' AQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1p
'' SIG '' Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1
'' SIG '' dF8yMDEwLTA2LTIzLmNydDANBgkqhkiG9w0BAQsFAAOC
'' SIG '' AgEAFPx8cVGlecJusu85Prw8Ug9uKz8QE3P+qGjQSKY0
'' SIG '' TYqWBSbuMUaQYXnW/zguRWv0wOUouNodj4rbCdcax0wK
'' SIG '' NmZqjOwb1wSQqBgXpJu54kAyNnbEwVrGv+QEwOoW06zD
'' SIG '' aO9irN1UbFAwWKbrfP6Up06O9Ox8hnNXwlIhczRa86OK
'' SIG '' VsgE2gcJ7fiL4870fo6u8PYLigj7P8kdcn9TuOu+Y+Dj
'' SIG '' PTFlsIHl8qzNFqSfPaixm8JC0JCEX1Qd/4nquh1HkG+w
'' SIG '' c05Bn0CfX+WhKrIRkXOKISjwzt5zOV8+q1xg7N8DEKjT
'' SIG '' Cen09paFtn9RiGZHGY2isBI9gSpoBXe7kUxie7bBB8e6
'' SIG '' eoc0Aw5LYnqZ6cr8zko3yS2kV3wc/j3cuA9a+tbEswKF
'' SIG '' Ajrqs9lu5GkhN96B0fZ1GQVn05NXXikbOcjuLeHN5EVz
'' SIG '' W9DSznqrFhmCRljQXp2Bs2evbDXyvOU/JOI1ogp1BvYY
'' SIG '' VpnUeCzRBRvr0IgBnaoQ8QXfun4sY7cGmyMhxPl4bOJY
'' SIG '' FwY2K5ESA8yk2fItuvmUnUDtGEXxzopcaz6rA9NwGCoK
'' SIG '' auBfR9HVYwoy8q/XNh8qcFrlQlkIcUtXun6DgfAhPPQc
'' SIG '' wcW5kJMOiEWThumxIJm+mMvFlaRdYtagYwggvXUQd309
'' SIG '' 80W5n5efy1eAbzOpBM93pGIcWX4xghaIMIIWhAIBATCB
'' SIG '' nDCBhDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
'' SIG '' bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
'' SIG '' FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEuMCwGA1UEAxMl
'' SIG '' TWljcm9zb2Z0IFdpbmRvd3MgUHJvZHVjdGlvbiBQQ0Eg
'' SIG '' MjAxMQITMwAAAjJB+1mZbcxN/wAAAAACMjANBglghkgB
'' SIG '' ZQMEAgEFAKCCAQQwGQYJKoZIhvcNAQkDMQwGCisGAQQB
'' SIG '' gjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcC
'' SIG '' ARUwLwYJKoZIhvcNAQkEMSIEIEwHNDVL7Ac8Zck/Q3ix
'' SIG '' LQVKRUMjMJWh1B84XuPtI/SNMDwGCisGAQQBgjcKAxwx
'' SIG '' LgwsUDVpMmFwbndUOTI2ME9jd0tuU0lQak1WTXZNamxx
'' SIG '' b3Q5eEo3OWxaQXVMND0wWgYKKwYBBAGCNwIBDDFMMEqg
'' SIG '' JIAiAE0AaQBjAHIAbwBzAG8AZgB0ACAAVwBpAG4AZABv
'' SIG '' AHcAc6EigCBodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20v
'' SIG '' d2luZG93czANBgkqhkiG9w0BAQEFAASCAQBkf3qvjzY4
'' SIG '' woR7AS+qJuzO/UVqEKmyzoHxW0UEmhZQRLVX+dl4NN4d
'' SIG '' FqFWQxSPHOFXGZNsHZ5x1ISq0lbMLoz6UtAUNG+JHeXU
'' SIG '' /JD0FsuAUU26NFhXPRTX69bbAR1Pht1T0N0/vV69NV7A
'' SIG '' 6UmNej1BoOqwahtw5QaZrKBexbOhsDAjBAygrXlIdU42
'' SIG '' oA1MmqkXqty3CGZK99ldkHxfCUYpFHvMXL0IuCBmL858
'' SIG '' Es/ThncjkVE1sUwJ5j6XvElrlQ3OijpoctKXhB62P/yj
'' SIG '' x0KPSkrJhtG1yRrOJm3oqQkGgRqeZLo+LHzGdnU2snd0
'' SIG '' /DYizF4WlfH279M8wPz3Um8QoYITtDCCE7AGCisGAQQB
'' SIG '' gjcDAwExghOgMIITnAYJKoZIhvcNAQcCoIITjTCCE4kC
'' SIG '' AQMxDzANBglghkgBZQMEAgEFADCCAVUGCyqGSIb3DQEJ
'' SIG '' EAEEoIIBRASCAUAwggE8AgEBBgorBgEEAYRZCgMBMDEw
'' SIG '' DQYJYIZIAWUDBAIBBQAEICuZW8l2cKbe4XDft6HI20+p
'' SIG '' fYe3d70M5HCY5tNptyUJAgZd5nWyzuoYEzIwMTkxMjA3
'' SIG '' MDQwNDAwLjQwOVowBIACAfSggdSkgdEwgc4xCzAJBgNV
'' SIG '' BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
'' SIG '' VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
'' SIG '' Q29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBP
'' SIG '' cGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1U
'' SIG '' aGFsZXMgVFNTIEVTTjoxNDhDLUM0QjktMjA2NjElMCMG
'' SIG '' A1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
'' SIG '' ZaCCDx8wggT1MIID3aADAgECAhMzAAABBmG1RJn46vLt
'' SIG '' AAAAAAEGMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYT
'' SIG '' AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
'' SIG '' EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
'' SIG '' cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1l
'' SIG '' LVN0YW1wIFBDQSAyMDEwMB4XDTE5MDkwNjIwNDExOVoX
'' SIG '' DTIwMTIwNDIwNDExOVowgc4xCzAJBgNVBAYTAlVTMRMw
'' SIG '' EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
'' SIG '' b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
'' SIG '' b24xKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25z
'' SIG '' IFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNT
'' SIG '' IEVTTjoxNDhDLUM0QjktMjA2NjElMCMGA1UEAxMcTWlj
'' SIG '' cm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCASIwDQYJ
'' SIG '' KoZIhvcNAQEBBQADggEPADCCAQoCggEBAK6/Y8FqdEu3
'' SIG '' czhDoYgvOn5R4P8vLjDUe+i1hLnpYnkLUyyuqm3davta
'' SIG '' YJCU5jqIcnwiLqtbTgoKiTn4Ls3EEeNadimFJu6ij+fo
'' SIG '' WxhKnAtaM52cUmJOxbcXOkr9nDe4PswdCBd/dkz8gA0b
'' SIG '' o8g+6zQvZz6K44EtBof+0yTgl1O9GyGmq5xSCFxLsJzm
'' SIG '' XJE7kbW/iAqFcl/Wp3NDIfmGH385H2IPKSjORDqs61c2
'' SIG '' Q4397ZtBF9RU/1r773/Shxie3KaB2pib3ob6r7zPjXz6
'' SIG '' zHGcLXatAeQVY84ulGMHWU/3EOPcXjZSuaAzCIzGj1VP
'' SIG '' 75Jxupfc7fP6/y4Kmi3AmWcCAwEAAaOCARswggEXMB0G
'' SIG '' A1UdDgQWBBT51LXZX41X57EFWSYJNAnoTm/TTDAfBgNV
'' SIG '' HSMEGDAWgBTVYzpcijGQ80N7fEYbxTNoWoVtVTBWBgNV
'' SIG '' HR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29m
'' SIG '' dC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNUaW1TdGFQ
'' SIG '' Q0FfMjAxMC0wNy0wMS5jcmwwWgYIKwYBBQUHAQEETjBM
'' SIG '' MEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29m
'' SIG '' dC5jb20vcGtpL2NlcnRzL01pY1RpbVN0YVBDQV8yMDEw
'' SIG '' LTA3LTAxLmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQM
'' SIG '' MAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEBCwUAA4IBAQCO
'' SIG '' hK1otduB6ttf+/yr5PqzyDKi1//lQnNw1YFkiGSmd0XC
'' SIG '' T0+fzNkwZoymXRMaJ197a9jDrexRjfC8syEPYCosClWf
'' SIG '' Myacdzye8QC7o+SiNUcM7B2B7hkulPKR9218iUAZKwb8
'' SIG '' 6tlWFpC72xzhZht4Uzr7MVrGKaK1aOGg1kWlao9vua7L
'' SIG '' /DyJfcK1LnjRwdmT0z9VAQoGen542Dz+QOSDNrjzjQLA
'' SIG '' 5kC/74It6dqir6aDHQVyttpBeJpPgZfr3tY/VR8uJIMV
'' SIG '' 2oQvfoz2mAXhd34AOHgiwqRs8jWYWjFExdLDjgofnvJ2
'' SIG '' tTAtz0BdN9qgrPYdT65K5ikxgYCMwGCdMIIGcTCCBFmg
'' SIG '' AwIBAgIKYQmBKgAAAAAAAjANBgkqhkiG9w0BAQsFADCB
'' SIG '' iDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
'' SIG '' b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
'' SIG '' Y3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWlj
'' SIG '' cm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
'' SIG '' IDIwMTAwHhcNMTAwNzAxMjEzNjU1WhcNMjUwNzAxMjE0
'' SIG '' NjU1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
'' SIG '' aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
'' SIG '' ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
'' SIG '' Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCC
'' SIG '' ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKkd
'' SIG '' Dbx3EYo6IOz8E5f1+n9plGt0VBDVpQoAgoX77XxoSyxf
'' SIG '' xcPlYcJ2tz5mK1vwFVMnBDEfQRsalR3OCROOfGEwWbEw
'' SIG '' RA/xYIiEVEMM1024OAizQt2TrNZzMFcmgqNFDdDq9UeB
'' SIG '' zb8kYDJYYEbyWEeGMoQedGFnkV+BVLHPk0ySwcSmXdFh
'' SIG '' E24oxhr5hoC732H8RsEnHSRnEnIaIYqvS2SJUGKxXf13
'' SIG '' Hz3wV3WsvYpCTUBR0Q+cBj5nf/VmwAOWRH7v0Ev9buWa
'' SIG '' yrGo8noqCjHw2k4GkbaICDXoeByw6ZnNPOcvRLqn9Nxk
'' SIG '' vaQBwSAJk3jN/LzAyURdXhacAQVPIk0CAwEAAaOCAeYw
'' SIG '' ggHiMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBTV
'' SIG '' YzpcijGQ80N7fEYbxTNoWoVtVTAZBgkrBgEEAYI3FAIE
'' SIG '' DB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0T
'' SIG '' AQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV9lbLj+iiXGJo
'' SIG '' 0T2UkFvXzpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRw
'' SIG '' Oi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9k
'' SIG '' dWN0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcmww
'' SIG '' WgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRw
'' SIG '' Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01p
'' SIG '' Y1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNydDCBoAYDVR0g
'' SIG '' AQH/BIGVMIGSMIGPBgkrBgEEAYI3LgMwgYEwPQYIKwYB
'' SIG '' BQUHAgEWMWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9Q
'' SIG '' S0kvZG9jcy9DUFMvZGVmYXVsdC5odG0wQAYIKwYBBQUH
'' SIG '' AgIwNB4yIB0ATABlAGcAYQBsAF8AUABvAGwAaQBjAHkA
'' SIG '' XwBTAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZIhvcN
'' SIG '' AQELBQADggIBAAfmiFEN4sbgmD+BcQM9naOhIW+z66bM
'' SIG '' 9TG+zwXiqf76V20ZMLPCxWbJat/15/B4vceoniXj+bzt
'' SIG '' a1RXCCtRgkQS+7lTjMz0YBKKdsxAQEGb3FwX/1z5Xhc1
'' SIG '' mCRWS3TvQhDIr79/xn/yN31aPxzymXlKkVIArzgPF/Uv
'' SIG '' eYFl2am1a+THzvbKegBvSzBEJCI8z+0DpZaPWSm8tv0E
'' SIG '' 4XCfMkon/VWvL/625Y4zu2JfmttXQOnxzplmkIz/amJ/
'' SIG '' 3cVKC5Em4jnsGUpxY517IW3DnKOiPPp/fZZqkHimbdLh
'' SIG '' nPkd/DjYlPTGpQqWhqS9nhquBEKDuLWAmyI4ILUl5WTs
'' SIG '' 9/S/fmNZJQ96LjlXdqJxqgaKD4kWumGnEcua2A5HmoDF
'' SIG '' 0M2n0O99g/DhO3EJ3110mCIIYdqwUB5vvfHhAN/nMQek
'' SIG '' kzr3ZUd46PioSKv33nJ+YWtvd6mBy6cJrDm77MbL2IK0
'' SIG '' cs0d9LiFAR6A+xuJKlQ5slvayA1VmXqHczsI5pgt6o3g
'' SIG '' My4SKfXAL1QnIffIrE7aKLixqduWsqdCosnPGUFN4Ib5
'' SIG '' KpqjEWYw07t0MkvfY3v1mYovG8chr1m1rtxEPJdQcdeh
'' SIG '' 0sVV42neV8HR3jDA/czmTfsNv11P6Z0eGTgvvM9YBS7v
'' SIG '' DaBQNdrvCScc1bN+NR4Iuto229Nfj950iEkSoYIDrTCC
'' SIG '' ApUCAQEwgf6hgdSkgdEwgc4xCzAJBgNVBAYTAlVTMRMw
'' SIG '' EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
'' SIG '' b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
'' SIG '' b24xKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25z
'' SIG '' IFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNT
'' SIG '' IEVTTjoxNDhDLUM0QjktMjA2NjElMCMGA1UEAxMcTWlj
'' SIG '' cm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIlCgEBMAkG
'' SIG '' BSsOAwIaBQADFQBjvfgaHlWFau4W8bvlsLzPVDXy+aCB
'' SIG '' 3jCB26SB2DCB1TELMAkGA1UEBhMCVVMxEzARBgNVBAgT
'' SIG '' Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
'' SIG '' BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEpMCcG
'' SIG '' A1UECxMgTWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVlcnRv
'' SIG '' IFJpY28xJzAlBgNVBAsTHm5DaXBoZXIgTlRTIEVTTjo0
'' SIG '' REU5LTBDNUUtM0UwOTErMCkGA1UEAxMiTWljcm9zb2Z0
'' SIG '' IFRpbWUgU291cmNlIE1hc3RlciBDbG9jazANBgkqhkiG
'' SIG '' 9w0BAQUFAAIFAOGVBukwIhgPMjAxOTEyMDcwMDU3MTNa
'' SIG '' GA8yMDE5MTIwODAwNTcxM1owdDA6BgorBgEEAYRZCgQB
'' SIG '' MSwwKjAKAgUA4ZUG6QIBADAHAgEAAgIFXTAHAgEAAgIY
'' SIG '' yjAKAgUA4ZZYaQIBADA2BgorBgEEAYRZCgQCMSgwJjAM
'' SIG '' BgorBgEEAYRZCgMBoAowCAIBAAIDB6EgoQowCAIBAAID
'' SIG '' B6EgMA0GCSqGSIb3DQEBBQUAA4IBAQBMqOZ68qGFwhlA
'' SIG '' hwJ+1WhZv29uIgnv93IggQSdMZcOCbZIO5iXF0GhEned
'' SIG '' hqh4LFeEHAkDMlNZozTeYl6JnQ5VN8l/3ACEck8DPL7T
'' SIG '' 8QuW4jJyD28RH0/hJ4bsyn6phrtcPYc1CQews/ccAQmY
'' SIG '' 2lPMmYFsRpB7/k796JhzI8M892wXVGMUu1YpBuq6hiBI
'' SIG '' /XsAWwadNRa2DPk76PodNARFsKogRvDylcxLiilF/l/i
'' SIG '' HT7VdmrwGW4n6rMV11WIp1JGtVsXHwmBhyMqMJVZlIxL
'' SIG '' hpZwUcW/iz+v9NuDpVqr0TVx5O5K1z4oPZ7Q8cePDdrg
'' SIG '' S07Wd+wujD7cFhI1ddh1MYIC9TCCAvECAQEwgZMwfDEL
'' SIG '' MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
'' SIG '' EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
'' SIG '' c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
'' SIG '' b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAEGYbVE
'' SIG '' mfjq8u0AAAAAAQYwDQYJYIZIAWUDBAIBBQCgggEyMBoG
'' SIG '' CSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG
'' SIG '' 9w0BCQQxIgQg/Syawf/9EyvLaD5Uj025i8+AQfEk7vpe
'' SIG '' R/8phXifjR0wgeIGCyqGSIb3DQEJEAIMMYHSMIHPMIHM
'' SIG '' MIGxBBRjvfgaHlWFau4W8bvlsLzPVDXy+TCBmDCBgKR+
'' SIG '' MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
'' SIG '' dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
'' SIG '' aWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
'' SIG '' Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB
'' SIG '' BmG1RJn46vLtAAAAAAEGMBYEFM8ozyHgcxFH/9ukI7t+
'' SIG '' VfMxW0mKMA0GCSqGSIb3DQEBCwUABIIBAKHMWbhB/1QV
'' SIG '' +/b4Bs0o19I/PwGbT/5MWEusvJ1vUe4pHAMs9+tMk/Lk
'' SIG '' TyEcq5snNtBnW2uj+Bm0Tn3rcBBA9cuf+WE2Xm7kikFL
'' SIG '' GRx5CmdDlxoiJqmyIWKP0PS8DOaG/15WMp5QHBMoNDe+
'' SIG '' QrcHp65Au97KFyFdLGx0x63Bu/jpknwdQevbuSz4NfNQ
'' SIG '' WuYm2q6R+glNv0mZ+vv4GG2ivjDjmPVbF+kLtqX/zYtA
'' SIG '' +VkicfnyTxUcxUzq2JkmxC0N4whQOMXn0JvX1+QOYyuh
'' SIG '' welj9ZVpEuZepj0BrGgrOEbE4f4tFMrTrq0XVvwS49+D
'' SIG '' Z9IRmHq4/Suyn9Wuoo9DPV4=
'' SIG '' End signature block
