 ' Roku Streaming Player Web Server
 ' This code was heavily influenced by darkhttpd/1.7
 ' The darkhttpd copyright notice is included below.

 '
 ' darkhttpd
 ' copyright (c) 2003-2008 Emil Mikulic.
 '
 ' Permission to use, copy, modify, and distribute this software for any
 ' purpose with or without fee is hereby granted, provided that the
 ' above copyright notice and this permission notice appear in all
 ' copies.
 ' 
 ' THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
 ' WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
 ' WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
 ' AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
 ' DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
 ' PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
 ' TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 ' PERFORMANCE OF THIS SOFTWARE.
 ' 

 ' Adapted from C to Brightscript with mods by Roku, Inc.
 '
 ' unimplemented options: daemonize, pidfile, logfile

 ' ---------------------------------------------------------------------------
 ' example Main to show how the server might be embedded
 ' in a more complex script that includes user interaction
 '
function Main()

    Init() ' set up defaults, read config file

    msgPort = CreateObject("roMessagePort")
    SetGlobal("msgPort",msgPort)

    ' control & status screen
    initTheme()
    screen = CreateObject("roPosterScreen")
    screen.SetBreadcrumbText("Web Server","Connections")
    screen.SetBreadcrumbEnabled(true)
    screen.setMessagePort(msgPort)
    screen.show()
    screenEvent = type(screen)+"Event"
    m.currentItem = 0

    server = InitServer()

    updateStatus(screen,server)
    ' trivial main loop
    m.running = true
    timeout = validint(Global("timeout"))
    timer = CreateObject("roTimespan")
    update = true
    while (m.running)
        if update
            timer.mark()
            updateStatus(screen,server)
            update = false
        end if
        server.prewait()
        msg = wait(timeout,msgPort)
        tm = type(msg)
        if tm="roSocketEvent" or msg=invalid
            server.postwait()
        else if tm=screenEvent
            if msg.isScreenClosed() then m.running = false
            if msg.isListItemFocused() then m.currentItem = msg.GetIndex()
            if msg.isListItemSelected()
                list = screen.getContentList()
                item = list[msg.getIndex()]
                connID = item.title
                conn = server.connections[connID]
                if (conn<>invalid)
                    conn.setState(conn.DONE)
                    conn.close = true
                    server.postwait()
                    update = true
                end if
            end if
        end if
        if timer.totalSeconds()>=5 then update = true
    end while

    server.close()

end function

function Init()
    ' set some global defaults
    globals = CreateObject("roAssociativeArray")
    globals.pkgname  = "Roku RSP WebServer"
    globals.maxRequestLength = 4000
    globals.idletime = 60
    globals.wwwroot = "pkg:/"
    globals.index_name = "index.html"
    globals.serverName = "Roku Streaming Player"
    globals.timeout = 5 * 1000 ' in milliseconds
    ' defaults before config file override
    AddGlobals(globals)
    MimeType()
    HttpTitle()
    ' might override some of above
    GetXMLConfig("config.xml",m)
end function

function updateStatus(screen as Object, server as Object)
    'screen.addParagraph(server.stats())
    connArray = []
    connections = server.connections
    for each connID in connections
        conn = connections[connID]
        connItem = {
            shortDescriptionLine1: conn.client
            shortDescriptionLine2: itostr(conn.total_sent)
            title                : conn.id
            HDPosterUrl          : "pkg:/images/Connection.png"
            SDPosterUrl          : "pkg:/images/Connection.png"
            contentType:           "movie"
        }
        connArray.push(connItem)
    end for
    screen.setContentList(connArray)
    cae = connArray.count()-1
    if (cae<0)
        screen.showMessage("No active connections" + UnixNL() + server.stats())
    else
        screen.clearMessage()
        if m.currentItem>cae then screen.SetFocusedListItem(cae)
    end if
    screen.Show()
end function

Sub initTheme()
    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    theme.OverhangSliceSD = "pkg:/images/Overhang_BackgroundSlice_SD43.png"
    'theme.OverhangPrimaryLogoOffsetSD_X = "72"
    'theme.OverhangPrimaryLogoOffsetSD_Y = "35"
    'theme.OverhangPrimaryLogoSD  = "pkg:/images/Logo_Overhang_SD43.png"

    theme.OverhangSliceHD = "pkg:/images/Overhang_BackgroundSlice_HD.png"
    'theme.OverhangPrimaryLogoOffsetHD_X = "123"
    'theme.OverhangPrimaryLogoOffsetHD_Y = "40"
    'theme.OverhangPrimaryLogoHD  = "pkg:/images/Logo_Overhang_HD.png"

    theme.BreadcrumbTextLeft = "#11BB11"
    theme.BreadcrumbDelimiter = "#111111"
    theme.BreadcrumbTextRight = "#11BB11"

    app.SetTheme(theme)
End Sub

