@echo off
title OCS Inventory NG Agent for Windows - Building required libraries
echo.
echo *************************************************************************
echo *                                                                       *
echo *                 OCS Inventory NG agent for Windows                    *
echo *                                                                       *
echo *                      Building required libraries                      *
echo *                                                                       *
echo *************************************************************************
echo.

Rem ========= UPDATE CONSTANTS BELOW TO MEET YOUR CONFIGURATION NEED =========  

Rem Set path to MS Visual C++
SET VC_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build

Rem Set path to Perl 5.6 or higher binary
SET PERL_PATH=C:\Strawberry\perl\bin

Rem Set OCS Agent compile folder
SET OCSAGENT_PATH=C:\Users\Admin\Documents\GitHub\WindowsAgent

Rem Set external deps path
SET EXT_DEPS=%OCSAGENT_PATH%\External_Deps

Rem Set path to Zlib sources
set ZLIB_PATH=%EXT_DEPS%\zlib-1.2.8

Rem Set path to OpenSSL sources
SET OPENSSL_PATH=%EXT_DEPS%\openssl-1.0.2r

Rem Set path to cURL sources
SET CURL_PATH=%EXT_DEPS%\curl-7.64.1\src

Rem Set path to tinyXML sources
SET XML_PATH=%EXT_DEPS%\tinyxml

Rem Set path to ZipArchive sources, for example
SET ZIP_PATH=%EXT_DEPS%\ZipArchive

Rem Set path to Net-SNMP sources, for example
SET SNMP_PATH=%EXT_DEPS%\net-snmp-5.7.3

Rem ========= DO NOT MODIFY BELOW, UNTIL YOU KNOW WHAT YOU ARE DOING =========

Rem Ensure MS Visual C++ environnement is set
call "%VC_PATH%\VCVARSALL.BAT" x64

Rem Add perl to PATH
set PATH=%PATH%;%PERL_PATH%

title OCS Inventory NG Agent for Windows - Building Zlib DLL...
echo.
echo *************************************************************************
echo *                                                                       *
echo * Preparing for OCS Inventory NG : Building Zlib DLL...                 *
echo *                                                                       *
echo *************************************************************************
echo.

cd "%ZLIB_PATH%"

Rem clean nmake 
nmake Win32\Makefile.msc clean
Rem Build Zlib using precompiled asm code for MS Visual C++ with lastest Service Pack ( -D_BIND_TO_CURRENT_VCLIBS_VERSION)
nmake /NOLOGO -f Win32\Makefile.msc AS=ml64 LOC="-DASMV -DASMINF -D_BIND_TO_CURRENT_VCLIBS_VERSION -I." OBJA="inffasx64.obj gvmat64.obj inffas8664.obj"
if ERRORLEVEL 1 goto ERROR

Rem copy libs to use them in OCS
copy zdll.lib %EXT_DEPS%
mkdir %OCSAGENT_PATH%\Release
copy zlib1.dll %OCSAGENT_PATH%\Release
mkdir %OCSAGENT_PATH%\Debug
copy zlib1.dll %OCSAGENT_PATH%\Debug
if ERRORLEVEL 1 goto ERROR

cd %EXT_DEPS%

title OCS Inventory NG Agent for Windows - Building OpenSSL DLLs...
echo.
echo *************************************************************************
echo *                                                                       *
echo * Preparing for OCS Inventory NG : Building OpenSSL DLLs...             *
echo *                                                                       *
echo *************************************************************************
echo.
cd "%OPENSSL_PATH%"

Rem Configure OpenSSL for MS Visual C++ with lastest Service Pack ( -D_BIND_TO_CURRENT_VCLIBS_VERSION)
perl.exe configure no-asm VC-WIN64A -D_BIND_TO_CURRENT_VCLIBS_VERSION -D_WINSOCK_DEPRECATED_NO_WARNINGS --openssldir=C:\Windows\openssl
if ERRORLEVEL 1 goto ERROR
Rem Prepare OpenSSL build for MS Visual C++
call ms\do_win64a
if ERRORLEVEL 1 goto ERROR
Rem Clean link form previous build
nmake /NOLOGO -f ms\ntdll.mak clean
Rem Build OpenSSL
nmake /NOLOGO -f ms\ntdll.mak
if ERRORLEVEL 1 goto ERROR
Rem Test OpenSSL build
cd out32dll
call "..\ms\test.bat"
if ERRORLEVEL 1 goto ERROR

Rem copy libs to use them in OCS
copy ssleay32.lib %EXT_DEPS%
copy libeay32.lib %EXT_DEPS%
copy libeay32.lib %EXT_DEPS%\curl-7.64.1\winbuild
copy ssleay32.lib %EXT_DEPS%\curl-7.64.1\winbuild
copy ssleay32.dll %OCSAGENT_PATH%\Release
copy libeay32.dll %OCSAGENT_PATH%\Release
copy ssleay32.dll %OCSAGENT_PATH%\Debug
copy libeay32.dll %OCSAGENT_PATH%\Debug
if ERRORLEVEL 1 goto ERROR

cd %EXT_DEPS%

title OCS Inventory NG Agent for Windows - Building cURL DLL...
echo.
echo *************************************************************************
echo *                                                                       *
echo * Preparing for OCS Inventory NG : Building cURL DLL...                 *
echo *                                                                       *
echo *************************************************************************
echo.
cd "%CURL_PATH%"
Rem Disable LDAP support, not needed in OCS Inventory NG Agent
set WINDOWS_SSPI=0
cd ..\winbuild
Rem Fix cURL DLL config for correct OpenSSL include path
perl.exe -pi.bak -e "s#\$\(SSL_PATH\)\\include#\$\(SSL_PATH\)#g" MakefileBuild.vc
Rem Fix cURL DLL config for MS Visual C++ with lastest Service Pack ( -D_BIND_TO_CURRENT_VCLIBS_VERSION)
Rem perl.exe -pi.bak -e "s# /DBUILDING_LIBCURL# /DBUILDING_LIBCURL /D_BIND_TO_CURRENT_VCLIBS_VERSION#g" Makefile.vc12
Rem Build cURL dll using OpenSSL Dlls and Zlib dll
Rem nmake /NOLOGO /f Makefile.vc12 cfg=release-dll-ssl-dll-zlib-dll
nmake /f Makefile.vc mode=dll VC=15 ENABLE_SSPI=NO ENABLE_IPV6=YES WITH_SSL=dll MACHINE=x64 SSL_PATH="%OPENSSL_PATH%\inc32" ZLIB_PATH="%ZLIB_PATH%"

if ERRORLEVEL 1 goto ERROR
Rem Insert manifest into DLL
rem cd ..\lib\release-dll-ssl-dll-zlib-dll
rem mt -manifest libcurl.dll.manifest -outputresource:libcurl.dll;2
if ERRORLEVEL 1 goto ERROR

Rem copy libs to use them in OCS
copy "..\builds\libcurl-vc15-x64-release-dll-ssl-dll-obj-lib\libcurl.lib" %EXT_DEPS%
copy "..\builds\libcurl-vc15-x64-release-dll-ssl-dll-obj-lib\libcurl.dll" %OCSAGENT_PATH%\Release
copy "..\builds\libcurl-vc15-x64-release-dll-ssl-dll-obj-lib\libcurl.dll" %OCSAGENT_PATH%\Debug
if ERRORLEVEL 1 goto ERROR

cd %EXT_DEPS%

title OCS Inventory NG Agent for Windows - Building Net-SNMP DLL...
echo.
echo *************************************************************************
echo *                                                                       *
echo * Preparing for OCS Inventory NG : Configuring Net-SNMP DLL...          *
echo *                                                                       *
echo *************************************************************************
echo.
cd "%SNMP_PATH%\win32"
Rem Prepare OpenSSL for Net-SNMP
SET INCLUDE=%INCLUDE%;%OPENSSL_PATH%\inc32
SET LIB=%LIB%;%OPENSSL_PATH%\out32dll
Rem Configure Net-SNMP
perl.exe Configure --config=release --with-ssl --linktype=dynamic
if ERRORLEVEL 1 goto ERROR
cd libsnmp_dll
Rem Fix Net-SNMP DLL config for MS Visual C++ with lastest Service Pack ( -D_BIND_TO_CURRENT_VCLIBS_VERSION)
perl.exe -pi.bak -e "s# /D \"WIN32\"# /D \"WIN32\" /D_BIND_TO_CURRENT_VCLIBS_VERSION#g" Makefile
Rem Fix Net-SNMP DLL config for using OpenSSL dynamic library insteadd of static ones
perl.exe -pi.bak -e "s#libeay32MD#libeay32#g" ../net-snmp/net-snmp-config.h
Rem Fix Net-SNMP DLL config for compile net-snmp with VS2017 
perl.exe -pi.bak -e "s#define snprintf  _snprintf##g" ../net-snmp/net-snmp-config.h

Rem Build Net-SNMP dll
nmake /NOLOGO
if ERRORLEVEL 1 goto ERROR
cd ..
copy "bin\release\netsnmp.dll" %OCSAGENT_PATH%\Release
copy "bin\release\netsnmp.dll" %OCSAGENT_PATH%\Debug
if ERRORLEVEL 1 goto ERROR
copy "lib\release\netsnmp.lib" %EXT_DEPS%
if ERRORLEVEL 1 goto ERROR

cd %EXT_DEPS%

title OCS Inventory NG Agent for Windows - Building ZipArchive DLL...
echo.
echo *************************************************************************
echo *                                                                       *
echo * Preparing for OCS Inventory NG : Building ZipArchive DLL...           *
echo *                                                                       *
echo *************************************************************************
echo.
cd "%ZIP_PATH%"
Rem Fix ZipArchive DLL config for MS Visual C++ with lastest Service Pack
perl.exe -pi.bak -e "s#_CRT_RAND_S;%%\(PreprocessorDefinitions\)</PreprocessorDefinitions>#_CRT_RAND_S;_BIND_TO_CURRENT_VCLIBS_VERSION;%%\(PreprocessorDefinitions\)</PreprocessorDefinitions>#g" ZipArchive.vcxproj
devenv ZipArchive.sln /Build "Release Unicode STL MD DLL|x64"
if ERRORLEVEL 1 goto ERROR
cd "x64\Release Unicode STL MD DLL"
Rem copy libs to use them in OCS
copy "ZipArchive.lib" %EXT_DEPS%
copy "ZipArchive.dll" %OCSAGENT_PATH%\Release
copy "ZipArchive.dll" %OCSAGENT_PATH%\Debug
if ERRORLEVEL 1 goto ERROR

cd %EXT_DEPS%

title OCS Inventory NG Agent for Windows - Building service message file...
echo.
echo *************************************************************************
echo *                                                                       *
echo * Preparing for OCS Inventory NG : Compiling service message file...    *
echo *                                                                       *
echo *************************************************************************
echo.
cd "%OCSAGENT_PATH%\Service"
mc.exe NTServiceMsg.mc
if ERRORLEVEL 1 goto ERROR

cd %EXT_DEPS%

title OCS Inventory NG Agent for Windows - SUCCESSFUL build of required libraries 
echo.
echo *************************************************************************
echo *                                                                       *
echo * Preparing for OCS Inventory NG : All done succesufully !              *
echo *                                                                       *
echo * Enjoy OCS Inventory NG ;-)                                            *
echo *                                                                       *
echo *************************************************************************
goto END

:ERROR
title OCS Inventory NG Agent for Windows - ERROR building required libraries  !!!!
echo.
echo *************************************************************************
echo *                                                                       *
echo * Preparing for OCS Inventory NG : Error while buiding required library *
echo *                                                                       *
echo * Please, fix problem before trying to build OCS Inventory NG !         *
echo *                                                                       *
echo * Here is some common errors:                                           *
echo * - Have you reviewed paths at the beginning of this batch file ?       *
echo * - Have you updated Visual C++ version in cURL Makefile ?              *
echo *                                                                       *
echo *************************************************************************

:END
