'----------------------------------------------------------------------
'    pubprn.vbs - publish printers from a non Windows 2000 server into Windows 2000 DS
'    
'
'     Arguments are:-
'        server - format server
'        DS container - format "LDAP:\\CN=...,DC=...."
'
'
'    Copyright (c) Microsoft Corporation 1997
'   All Rights Reserved
'----------------------------------------------------------------------

'--- Begin Error Strings ---

Dim L_PubprnUsage1_text
Dim L_PubprnUsage2_text
Dim L_PubprnUsage3_text      
Dim L_PubprnUsage4_text      
Dim L_PubprnUsage5_text      
Dim L_PubprnUsage6_text      

Dim L_GetObjectError1_text
Dim L_GetObjectError2_text

Dim L_PublishError1_text
Dim L_PublishError2_text     
Dim L_PublishError3_text
Dim L_PublishSuccess1_text


L_PubprnUsage1_text      =   "Usage: [cscript] pubprn.vbs server ""LDAP://OU=..,DC=..."""
L_PubprnUsage2_text      =   "       server is a Windows server name (e.g.: Server) or UNC printer name (\\Server\Printer)"
L_PubprnUsage3_text      =   "       ""LDAP://CN=...,DC=..."" is the DS path of the target container"
L_PubprnUsage4_text      =   ""
L_PubprnUsage5_text      =   "Example 1: pubprn.vbs MyServer ""LDAP://CN=MyContainer,DC=MyDomain,DC=Company,DC=Com"""
L_PubprnUsage6_text      =   "Example 2: pubprn.vbs \\MyServer\Printer ""LDAP://CN=MyContainer,DC=MyDomain,DC=Company,DC=Com"""

L_GetObjectError1_text   =   "Error: Path "
L_GetObjectError2_text   =   " not found."
L_GetObjectError3_text   =   "Error: Unable to access "

L_PublishError1_text     =   "Error: Pubprn cannot publish printers from "
L_PublishError2_text     =   " because it is running Windows 2000, or later."
L_PublishError3_text     =   "Failed to publish printer "
L_PublishError4_text     =   "Error: "
L_PublishSuccess1_text   =   "Published printer: "

'--- End Error Strings ---


set Args = Wscript.Arguments
if args.count < 2 then
    wscript.echo L_PubprnUsage1_text
    wscript.echo L_PubprnUsage2_text
    wscript.echo L_PubprnUsage3_text
    wscript.echo L_PubprnUsage4_text
    wscript.echo L_PubprnUsage5_text
    wscript.echo L_PubprnUsage6_text
    wscript.quit(1)
end if

ServerName= args(0)
Container = args(1)

if 1 <> InStr(1, Container, "LDAP://", vbTextCompare) then
    wscript.echo L_GetObjectError1_text & Container & L_GetObjectError2_text
    wscript.quit(1)
end if

on error resume next
Set PQContainer = GetObject(Container)

if err then
    wscript.echo L_GetObjectError1_text & Container & L_GetObjectError2_text
    wscript.quit(1)
end if
on error goto 0



if left(ServerName,1) = "\" then

    PublishPrinter ServerName, ServerName, Container

else

    on error resume next

    Set PrintServer = GetObject("WinNT://" & ServerName & ",computer")

    if err then
        wscript.echo L_GetObjectError3_text & ServerName & ": " & err.Description
        wscript.quit(1)
    end if

    on error goto 0


    For Each Printer In PrintServer
        if Printer.class = "PrintQueue" then PublishPrinter Printer.PrinterPath, ServerName, Container
    Next


end if




sub PublishPrinter(UNC, ServerName, Container)

    
    Set PQ = WScript.CreateObject("OlePrn.DSPrintQueue.1")

    PQ.UNCName = UNC
    PQ.Container = Container

    on error resume next

    PQ.Publish(2)

    if err then
        if err.number = -2147024772 then
            wscript.echo L_PublishError1_text & Chr(34) & ServerName & Chr(34) & L_PublishError2_text
            wscript.quit(1)
        else
            wscript.echo L_PublishError3_text & Chr(34) & UNC & Chr(34) & "."
            wscript.echo L_PublishError4_text & err.Description
        end if
    else
        wscript.echo L_PublishSuccess1_text & PQ.Path
    end if

    Set PQ = nothing

end sub

'' SIG '' Begin signature block
'' SIG '' MIIiGAYJKoZIhvcNAQcCoIIiCTCCIgUCAQExDzANBglg
'' SIG '' hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
'' SIG '' BgEEAYI3AgEeMCQCAQEEEE7wKRaZJ7VNj+Ws4Q8X66sC
'' SIG '' AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' bX5L2iwVxdNwgYz/bum9hpiY7tSWABk75hj61B/d9mGg
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
'' SIG '' 80W5n5efy1eAbzOpBM93pGIcWX4xghaLMIIWhwIBATCB
'' SIG '' nDCBhDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
'' SIG '' bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
'' SIG '' FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEuMCwGA1UEAxMl
'' SIG '' TWljcm9zb2Z0IFdpbmRvd3MgUHJvZHVjdGlvbiBQQ0Eg
'' SIG '' MjAxMQITMwAAAjJB+1mZbcxN/wAAAAACMjANBglghkgB
'' SIG '' ZQMEAgEFAKCCAQQwGQYJKoZIhvcNAQkDMQwGCisGAQQB
'' SIG '' gjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcC
'' SIG '' ARUwLwYJKoZIhvcNAQkEMSIEIAzqtXfm1GQ71LVHrCDZ
'' SIG '' w7Sx4Nje4atwX+SJyHGrQDCgMDwGCisGAQQBgjcKAxwx
'' SIG '' Lgwsd2lzakVheENGcElvQnk5enE3VC9DRmVqWXkyRGF3
'' SIG '' S2dkNUt6V2RkK2xmOD0wWgYKKwYBBAGCNwIBDDFMMEqg
'' SIG '' JIAiAE0AaQBjAHIAbwBzAG8AZgB0ACAAVwBpAG4AZABv
'' SIG '' AHcAc6EigCBodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20v
'' SIG '' d2luZG93czANBgkqhkiG9w0BAQEFAASCAQAJpvkkjlIN
'' SIG '' i731ho4WIsxjD5f9k4XvBxZkmJ6VU+MGsMKWlja9PWWf
'' SIG '' 1htF85u6oUXVFgfvyFMGsb27koEKAF9pLRuAVYhaT21C
'' SIG '' c8fjWRsJTaiJLS91ttGB2vydDF+j3UO6/7DNS7XoxsAf
'' SIG '' J8RGAOr8XvNONF0wegondjDrVJomMFLXjawYj7cJNJq+
'' SIG '' THx8jAlZvpCV7e0V6wSoTyEmZtdwzKn2hFv3KS+wnvs5
'' SIG '' 94CjMx2208vHSkVixHhAHuAJk3Fzd95UkoZsoWJMIoOZ
'' SIG '' 9UjrpnNWaxwWrlIMYv7MDvsoDwyOpoZlMwULSLU8bJta
'' SIG '' x9qlraIjaPCL2O9rUVd9TBLfoYITtzCCE7MGCisGAQQB
'' SIG '' gjcDAwExghOjMIITnwYJKoZIhvcNAQcCoIITkDCCE4wC
'' SIG '' AQMxDzANBglghkgBZQMEAgEFADCCAVgGCyqGSIb3DQEJ
'' SIG '' EAEEoIIBRwSCAUMwggE/AgEBBgorBgEEAYRZCgMBMDEw
'' SIG '' DQYJYIZIAWUDBAIBBQAEIJt0YF418oc6+ltthIHSVI2Z
'' SIG '' sy1NwvhczSZzvmTdHo+tAgZd5pJYGsIYEzIwMTkxMjA3
'' SIG '' MDQwMzU4LjgyNVowBwIBAYACAfSggdSkgdEwgc4xCzAJ
'' SIG '' BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
'' SIG '' DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
'' SIG '' ZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29m
'' SIG '' dCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQL
'' SIG '' Ex1UaGFsZXMgVFNTIEVTTjpCQkVDLTMwQ0EtMkRCRTEl
'' SIG '' MCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
'' SIG '' dmljZaCCDx8wggT1MIID3aADAgECAhMzAAAA/y+eawUR
'' SIG '' 02uXAAAAAAD/MA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNV
'' SIG '' BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
'' SIG '' VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
'' SIG '' Q29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBU
'' SIG '' aW1lLVN0YW1wIFBDQSAyMDEwMB4XDTE5MDkwNjIwNDEw
'' SIG '' OVoXDTIwMTIwNDIwNDEwOVowgc4xCzAJBgNVBAYTAlVT
'' SIG '' MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
'' SIG '' ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
'' SIG '' YXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRp
'' SIG '' b25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMg
'' SIG '' VFNTIEVTTjpCQkVDLTMwQ0EtMkRCRTElMCMGA1UEAxMc
'' SIG '' TWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCASIw
'' SIG '' DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAK4I64gt
'' SIG '' w/4t9QSoYitca8Kv6YQVGnLbSDE00yRkj6RWIT+uxgfd
'' SIG '' 4i2ZB9rAid18/Vsqn7UnZveZdcnuqrAxiV+WlzipNz8e
'' SIG '' A4HIhre0WZQRY3+MMErMT0W5wUcqA9PyC0SdUY6D2HcR
'' SIG '' LfMgmPXx36xVVxumCa628kqikaXW729M3AvF0fdLi36i
'' SIG '' /VKA6CxMXQJuUmK7/N2LCxDOy2T7edA+OT4OXB8QLmTA
'' SIG '' 6uJw9XRAxoL+r4G6P7isFQC8Mpv828GpG0mm2ZP1Lkdk
'' SIG '' 5eJ0UybaLZIlUrSwRqY7Dr0lqPWYHluSzIw/Q8W20ZhX
'' SIG '' GHTZ1MEMboBuZMISv1squA8GNbECAwEAAaOCARswggEX
'' SIG '' MB0GA1UdDgQWBBTOGdbw37F8Vnyj7dvFNnIwQFfWATAf
'' SIG '' BgNVHSMEGDAWgBTVYzpcijGQ80N7fEYbxTNoWoVtVTBW
'' SIG '' BgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jv
'' SIG '' c29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNUaW1T
'' SIG '' dGFQQ0FfMjAxMC0wNy0wMS5jcmwwWgYIKwYBBQUHAQEE
'' SIG '' TjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jv
'' SIG '' c29mdC5jb20vcGtpL2NlcnRzL01pY1RpbVN0YVBDQV8y
'' SIG '' MDEwLTA3LTAxLmNydDAMBgNVHRMBAf8EAjAAMBMGA1Ud
'' SIG '' JQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEBCwUAA4IB
'' SIG '' AQCkCdpCWO4VbhSMSsyAefgtYdWh3neq3D/0UREg2FPq
'' SIG '' 0f8R3qfoDMNx94F2vi1prGjl0H6O5YzqcNDB332Qie4q
'' SIG '' Tt+pGXF3tmYmWQVDowB0vN0kMZdKRLsjdpHsT+kqcFXV
'' SIG '' jqBsgK494zUJM9hI7bqvJ9Yzfr88a7Ui/UkY2Qk4bzZf
'' SIG '' YndKIAI8UjMJp7EArg/1sQ9zwaGp0d3FzvHR9V47D4S8
'' SIG '' FqccVrzaGbPYcL8kxojjJHsm1GAqNllO44hYGqReYMVw
'' SIG '' VpOB8WXiMkt3BAJ2QxvjB8uBV1z8nKbicmuoFkVNvSaQ
'' SIG '' Bhvo6QrWHqA2huTr2YU7nKMNOLDyE8ZlGiuSMIIGcTCC
'' SIG '' BFmgAwIBAgIKYQmBKgAAAAAAAjANBgkqhkiG9w0BAQsF
'' SIG '' ADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
'' SIG '' bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
'' SIG '' FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMp
'' SIG '' TWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9y
'' SIG '' aXR5IDIwMTAwHhcNMTAwNzAxMjEzNjU1WhcNMjUwNzAx
'' SIG '' MjE0NjU1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
'' SIG '' V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
'' SIG '' A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
'' SIG '' VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
'' SIG '' MDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
'' SIG '' AKkdDbx3EYo6IOz8E5f1+n9plGt0VBDVpQoAgoX77Xxo
'' SIG '' SyxfxcPlYcJ2tz5mK1vwFVMnBDEfQRsalR3OCROOfGEw
'' SIG '' WbEwRA/xYIiEVEMM1024OAizQt2TrNZzMFcmgqNFDdDq
'' SIG '' 9UeBzb8kYDJYYEbyWEeGMoQedGFnkV+BVLHPk0ySwcSm
'' SIG '' XdFhE24oxhr5hoC732H8RsEnHSRnEnIaIYqvS2SJUGKx
'' SIG '' Xf13Hz3wV3WsvYpCTUBR0Q+cBj5nf/VmwAOWRH7v0Ev9
'' SIG '' buWayrGo8noqCjHw2k4GkbaICDXoeByw6ZnNPOcvRLqn
'' SIG '' 9NxkvaQBwSAJk3jN/LzAyURdXhacAQVPIk0CAwEAAaOC
'' SIG '' AeYwggHiMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQW
'' SIG '' BBTVYzpcijGQ80N7fEYbxTNoWoVtVTAZBgkrBgEEAYI3
'' SIG '' FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
'' SIG '' VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV9lbLj+ii
'' SIG '' XGJo0T2UkFvXzpoYxDBWBgNVHR8ETzBNMEugSaBHhkVo
'' SIG '' dHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9w
'' SIG '' cm9kdWN0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5j
'' SIG '' cmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5o
'' SIG '' dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRz
'' SIG '' L01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNydDCBoAYD
'' SIG '' VR0gAQH/BIGVMIGSMIGPBgkrBgEEAYI3LgMwgYEwPQYI
'' SIG '' KwYBBQUHAgEWMWh0dHA6Ly93d3cubWljcm9zb2Z0LmNv
'' SIG '' bS9QS0kvZG9jcy9DUFMvZGVmYXVsdC5odG0wQAYIKwYB
'' SIG '' BQUHAgIwNB4yIB0ATABlAGcAYQBsAF8AUABvAGwAaQBj
'' SIG '' AHkAXwBTAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZI
'' SIG '' hvcNAQELBQADggIBAAfmiFEN4sbgmD+BcQM9naOhIW+z
'' SIG '' 66bM9TG+zwXiqf76V20ZMLPCxWbJat/15/B4vceoniXj
'' SIG '' +bzta1RXCCtRgkQS+7lTjMz0YBKKdsxAQEGb3FwX/1z5
'' SIG '' Xhc1mCRWS3TvQhDIr79/xn/yN31aPxzymXlKkVIArzgP
'' SIG '' F/UveYFl2am1a+THzvbKegBvSzBEJCI8z+0DpZaPWSm8
'' SIG '' tv0E4XCfMkon/VWvL/625Y4zu2JfmttXQOnxzplmkIz/
'' SIG '' amJ/3cVKC5Em4jnsGUpxY517IW3DnKOiPPp/fZZqkHim
'' SIG '' bdLhnPkd/DjYlPTGpQqWhqS9nhquBEKDuLWAmyI4ILUl
'' SIG '' 5WTs9/S/fmNZJQ96LjlXdqJxqgaKD4kWumGnEcua2A5H
'' SIG '' moDF0M2n0O99g/DhO3EJ3110mCIIYdqwUB5vvfHhAN/n
'' SIG '' MQekkzr3ZUd46PioSKv33nJ+YWtvd6mBy6cJrDm77MbL
'' SIG '' 2IK0cs0d9LiFAR6A+xuJKlQ5slvayA1VmXqHczsI5pgt
'' SIG '' 6o3gMy4SKfXAL1QnIffIrE7aKLixqduWsqdCosnPGUFN
'' SIG '' 4Ib5KpqjEWYw07t0MkvfY3v1mYovG8chr1m1rtxEPJdQ
'' SIG '' cdeh0sVV42neV8HR3jDA/czmTfsNv11P6Z0eGTgvvM9Y
'' SIG '' BS7vDaBQNdrvCScc1bN+NR4Iuto229Nfj950iEkSoYID
'' SIG '' rTCCApUCAQEwgf6hgdSkgdEwgc4xCzAJBgNVBAYTAlVT
'' SIG '' MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
'' SIG '' ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
'' SIG '' YXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRp
'' SIG '' b25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMg
'' SIG '' VFNTIEVTTjpCQkVDLTMwQ0EtMkRCRTElMCMGA1UEAxMc
'' SIG '' TWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIlCgEB
'' SIG '' MAkGBSsOAwIaBQADFQACNsQ1aM82D0wUzHu4sbw6yDp3
'' SIG '' HaCB3jCB26SB2DCB1TELMAkGA1UEBhMCVVMxEzARBgNV
'' SIG '' BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
'' SIG '' HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEp
'' SIG '' MCcGA1UECxMgTWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVl
'' SIG '' cnRvIFJpY28xJzAlBgNVBAsTHm5DaXBoZXIgTlRTIEVT
'' SIG '' Tjo0REU5LTBDNUUtM0UwOTErMCkGA1UEAxMiTWljcm9z
'' SIG '' b2Z0IFRpbWUgU291cmNlIE1hc3RlciBDbG9jazANBgkq
'' SIG '' hkiG9w0BAQUFAAIFAOGUoDQwIhgPMjAxOTEyMDYxNzM5
'' SIG '' MDBaGA8yMDE5MTIwNzE3MzkwMFowdDA6BgorBgEEAYRZ
'' SIG '' CgQBMSwwKjAKAgUA4ZSgNAIBADAHAgEAAgIlajAHAgEA
'' SIG '' AgIaWTAKAgUA4ZXxtAIBADA2BgorBgEEAYRZCgQCMSgw
'' SIG '' JjAMBgorBgEEAYRZCgMBoAowCAIBAAIDFuNgoQowCAIB
'' SIG '' AAIDB6EgMA0GCSqGSIb3DQEBBQUAA4IBAQCh0/v3LWzM
'' SIG '' vfgN7BdMYAfWaGJxRubIGyMPZQWaJegfgdHzpkLcZSJb
'' SIG '' eL/Qnd+YV/EUxZLpNghwEDr9bJvYKooDqfHySFp9Mlxj
'' SIG '' qg8lft58VdFu9Qo1vDvdmLSy7m991TLhlcosjU8oCRkp
'' SIG '' /4UF+B8b8o8lrE3D1XJTAPvJI9mJpHdDwb87yKRvy2Bz
'' SIG '' XMjNDIfxNqFf4RqzcslooB3qxe4ZZb48Y03D5WeGrBEp
'' SIG '' deYBqcV5dyKx14xfoX9JZleAVD8slua0syOHrGzc+vlN
'' SIG '' VLuiHxc+4UEMZKVy+fiO+g67rolIYFjr2HH8z1MgvvP6
'' SIG '' 8PkOAjxfEuyb5TjXBHw94UcnMYIC9TCCAvECAQEwgZMw
'' SIG '' fDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
'' SIG '' b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
'' SIG '' Y3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWlj
'' SIG '' cm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAD/
'' SIG '' L55rBRHTa5cAAAAAAP8wDQYJYIZIAWUDBAIBBQCgggEy
'' SIG '' MBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkq
'' SIG '' hkiG9w0BCQQxIgQgr2ZctWjKt+IT6aueCtYNPHhxI7ri
'' SIG '' FX2QgDVHocgpFZ4wgeIGCyqGSIb3DQEJEAIMMYHSMIHP
'' SIG '' MIHMMIGxBBQCNsQ1aM82D0wUzHu4sbw6yDp3HTCBmDCB
'' SIG '' gKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
'' SIG '' aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
'' SIG '' ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMT
'' SIG '' HU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMz
'' SIG '' AAAA/y+eawUR02uXAAAAAAD/MBYEFOmM5JM7lo4i5lYu
'' SIG '' 0drMGdjU+c9tMA0GCSqGSIb3DQEBCwUABIIBAKWsY8BT
'' SIG '' LnhpeV4mhK/JddcyEv7BIZVF0SEzfH/BNzr48754mZRN
'' SIG '' bKh1gIHDdNffRPSeUVb9D6jplW07ju4kSSe3WnOWmvaj
'' SIG '' fi3O51h/9QXqcd0ZW47aNBt29e9d9JyTT0txXjsXbL5H
'' SIG '' 36ssY9wqIvR0RXV0LDUBw53K/5w/rPMvH7lybLaRMwHM
'' SIG '' eJo1/8hjkW6l2NkMj/M9D/PcEix+8w0ucUE9uDp2Qr7g
'' SIG '' CE3N6tmXMqu3+RHUf1KoRnfXwLGrc0Dx1MyMe837owxp
'' SIG '' VWrte8t662VZ6o22LqRiUzF9lJ9mXETjrfDcvx0e2D+p
'' SIG '' U8O2rIehwlJfJCrkumm+nKG0S80=
'' SIG '' End signature block
